import { afterEach, beforeEach, describe, expect, mock, test } from "bun:test";

const USAGE_PAYLOAD = {
  usage: {
    rolling: { status: "ok", percent: 6, resetsAt: "2026-08-19T18:41:17.679Z" },
    weekly: { status: "ok", percent: 2, resetsAt: "2026-08-24T00:00:00.679Z" },
    monthly: { status: "ok", percent: 13, resetsAt: "2026-09-05T22:18:43.679Z" },
  },
};

// monthly.resetsAt(2026-09-05T22:18:43.679Z) とちょうど 17 日差になる時刻にする
const NOW = Date.parse("2026-08-19T22:18:43.679Z");

const {
  default: createExtension,
  parseUsageResponse,
  buildSegmentPayload,
  pickCritical,
  formatReset,
  colorForPercent,
} = await import("../../conf/.pi/agent/extensions/opencode-go-rate-limit.ts");

type Handler = (event: any, ctx: any) => Promise<void> | void;

type Emit = { channel: string; data: any };

/** キャプチャした setInterval コールバック（タイマー動作のテスト用） */
const intervals: Array<() => void> = [];
const clearCalls: number[] = [];

function captureTimers(): void {
  let id = 0;
  globalThis.setInterval = mock((fn: () => void) => {
    intervals.push(fn);
    return ++id;
  }) as any;
  globalThis.clearInterval = mock((timerId: number) => {
    clearCalls.push(timerId);
  }) as any;
}

function restoreTimers(): void {
  // bun:test の mock は auto-restore されるため何もしない
}

const fetchMock = mock(async () => {
  return new Response(JSON.stringify(USAGE_PAYLOAD), {
    status: 200,
    headers: { "content-type": "application/json" },
  });
});

function setupExtension() {
  const handlers = new Map<string, Handler>();
  const emits: Emit[] = [];
  const pi = {
    on: (event: string, handler: Handler) => handlers.set(event, handler),
    events: {
      emit: (channel: string, data: unknown) => emits.push({ channel, data }),
      on: () => () => {},
    },
  };

  createExtension(pi as any);

  const makeCtx = (model?: { provider: string; id: string }) => ({
    cwd: "/tmp/project",
    hasUI: true,
    model,
    ui: { theme: { fg: (color: string, text: string) => `${color}:${text}` } },
  });

  return { handlers, emits, pi, makeCtx };
}

function lastUpdate(emits: Emit[]): any {
  return [...emits].reverse().find((e) => e.channel === "powerbar:update")?.data;
}

/** fetch モックの Promise チェーンが解決するまで待つ */
async function flush(): Promise<void> {
  for (let i = 0; i < 5; i++) {
    await Promise.resolve();
  }
}

describe("parseUsageResponse", () => {
  test("実測スキーマ（usage.percent + resetsAt）をパースする", () => {
    const usage = parseUsageResponse(USAGE_PAYLOAD, NOW);

    expect(usage).toEqual({
      windows: [
        {
          key: "rolling",
          label: "5h",
          status: "ok",
          percent: 6,
          resetsAt: Date.parse("2026-08-19T18:41:17.679Z"),
        },
        {
          key: "weekly",
          label: "wk",
          status: "ok",
          percent: 2,
          resetsAt: Date.parse("2026-08-24T00:00:00.679Z"),
        },
        {
          key: "monthly",
          label: "mo",
          status: "ok",
          percent: 13,
          resetsAt: Date.parse("2026-09-05T22:18:43.679Z"),
        },
      ],
    });
  });

  test("別スキーマ（usagePercent + resetsInSeconds、トップレベル直下）も防御的にパースする", () => {
    const usage = parseUsageResponse(
      {
        rolling: { status: "ok", usagePercent: 45, resetsInSeconds: 12_345 },
        weekly: { status: "ok", usagePercent: 30, resetsInSeconds: 123_456 },
        monthly: { status: "ok", usagePercent: 15, resetsInSeconds: 1_234_567 },
      },
      NOW,
    );

    expect(usage?.windows).toEqual([
      {
        key: "rolling",
        label: "5h",
        status: "ok",
        percent: 45,
        resetsAt: NOW + 12_345_000,
      },
      {
        key: "weekly",
        label: "wk",
        status: "ok",
        percent: 30,
        resetsAt: NOW + 123_456_000,
      },
      {
        key: "monthly",
        label: "mo",
        status: "ok",
        percent: 15,
        resetsAt: NOW + 1_234_567_000,
      },
    ]);
  });

  test("不正ペイロードでは undefined を返す", () => {
    expect(parseUsageResponse(null, NOW)).toBeUndefined();
    expect(parseUsageResponse({ foo: 1 }, NOW)).toBeUndefined();
    expect(parseUsageResponse({ usage: {} }, NOW)).toBeUndefined();
    expect(
      parseUsageResponse({ usage: { rolling: { status: "ok" } } }, NOW),
    ).toBeUndefined();
  });

  test("percent は 0-100 にクランプされ、欠落した窓はスキップされる", () => {
    const usage = parseUsageResponse(
      {
        usage: {
          rolling: { status: "ok", percent: 150, resetsAt: "x" },
          weekly: { status: "ok", percent: -5 },
          monthly: { status: "ok", percent: 13 },
        },
      },
      NOW,
    );

    expect(usage?.windows.map((w) => [w.label, w.percent])).toEqual([
      ["5h", 100],
      ["wk", 0],
      ["mo", 13],
    ]);
  });
});

describe("buildSegmentPayload / pickCritical / formatReset / colorForPercent", () => {
  test("3窓の%テキストと最重要窓のバー・reset 残り時間を組み立てる", () => {
    const usage = parseUsageResponse(USAGE_PAYLOAD, NOW)!;
    const payload = buildSegmentPayload(usage, NOW);

    expect(payload).not.toBeUndefined();
    expect(payload!.text).toBe("5h 6% · wk 2% · mo 13%");
    expect(payload!.bar).toBe(13);
    expect(payload!.suffix).toBe("reset 17d");
    expect(payload!.color).toBe("success");
  });

  test("最重要窓以外のリセット時間は使わず、最重要窓の残り時間を表示する", () => {
    const usage = {
      windows: [
        {
          key: "rolling",
          label: "5h",
          status: "ok",
          percent: 55,
          resetsAt: NOW + 45 * 60_000, // 45m
        },
        {
          key: "weekly",
          label: "wk",
          status: "ok",
          percent: 10,
          resetsAt: NOW + 3 * 3_600_000, // 3h
        },
        {
          key: "monthly",
          label: "mo",
          status: "ok",
          percent: 5,
          resetsAt: NOW + 17 * 86_400_000,
        },
      ],
    };
    const payload = buildSegmentPayload(usage as any, NOW);
    expect(payload!.suffix).toBe("reset 45m");
    expect(payload!.color).toBe("warning");
  });

  test("最重要窓は percent 最大のウィンドウ（同率なら 5h > wk > mo）", () => {
    const usage = {
      windows: [
        { key: "weekly", label: "wk", status: "ok", percent: 30, resetsAt: NOW + 100 },
        { key: "monthly", label: "mo", status: "ok", percent: 55, resetsAt: NOW + 200 },
        { key: "rolling", label: "5h", status: "ok", percent: 10, resetsAt: NOW + 300 },
      ],
    };
    expect(pickCritical(usage as any)?.key).toBe("monthly");

    const tied = {
      windows: [
        { key: "weekly", label: "wk", status: "ok", percent: 40, resetsAt: 0 },
        { key: "rolling", label: "5h", status: "ok", percent: 40, resetsAt: 0 },
        { key: "monthly", label: "mo", status: "ok", percent: 40, resetsAt: 0 },
      ],
    };
    expect(pickCritical(tied as any)?.key).toBe("rolling");
  });

  test("色分け閾値: <50 は success / 50-79 は warning / >=80 は error", () => {
    expect(colorForPercent(45, false)).toBe("success");
    expect(colorForPercent(50, false)).toBe("warning");
    expect(colorForPercent(79, false)).toBe("warning");
    expect(colorForPercent(80, false)).toBe("error");
  });

  test("status が ok でない窓があれば error になる", () => {
    const usage = parseUsageResponse(
      {
        usage: {
          rolling: { status: "limited", percent: 100, resetsAt: "2026-08-19T19:00:00Z" },
          weekly: { status: "ok", percent: 5, resetsAt: "2026-08-24T00:00:00Z" },
          monthly: { status: "ok", percent: 5, resetsAt: "2026-09-05T00:00:00Z" },
        },
      },
      NOW,
    )!;

    const payload = buildSegmentPayload(usage, NOW);
    expect(payload!.color).toBe("error");
    expect(payload!.suffix).toContain("! 5h limit");
  });

  test("formatReset は残り時間を人間が読める形にする", () => {
    expect(formatReset(NOW + 30_000, NOW)).toBe("1m");
    expect(formatReset(NOW + 2.5 * 3_600_000, NOW)).toBe("2h30m");
    expect(formatReset(NOW + 17 * 86_400_000, NOW)).toBe("17d");
    expect(formatReset(NOW - 1000, NOW)).toBe("now");
  });

  test("空の usage では undefined を返す", () => {
    expect(buildSegmentPayload({ windows: [] } as any, NOW)).toBeUndefined();
  });
});

describe("extension のイベント動作", () => {
  beforeEach(() => {
    fetchMock.mockClear();
    fetchMock.mockImplementation(async () => {
      return new Response(JSON.stringify(USAGE_PAYLOAD), {
        status: 200,
        headers: { "content-type": "application/json" },
      });
    });
    globalThis.fetch = fetchMock as any;
    process.env.OPENCODE_GO_API_KEY = "test-key";
    intervals.length = 0;
    clearCalls.length = 0;
    captureTimers();
  });

  afterEach(() => {
    delete process.env.OPENCODE_GO_API_KEY;
    restoreTimers();
  });

  test("session_start で opencode-go アクティブなら fetch して powerbar:update を emit する", async () => {
    const { handlers, emits, makeCtx } = setupExtension();

    await handlers.get("session_start")?.(
      { reason: "startup" },
      makeCtx({ provider: "opencode-go", id: "deepseek-v4-flash" }),
    );
    await flush();

    expect(fetchMock).toHaveBeenCalledTimes(1);
    const url = fetchMock.mock.calls[0][0] as string;
    expect(url).toBe("https://opencode.ai/zen/go/v1/usage");
    expect((fetchMock.mock.calls[0][1] as any).headers.Authorization).toBe(
      "Bearer test-key",
    );

    const update = lastUpdate(emits);
    expect(update.id).toBe("opencode-go");
    expect(update.text).toContain("5h 6%");
    expect(update.bar).toBeGreaterThan(0);
  });

  test("session_start で opencode-go 以外のモデルならセグメントをクリアし fetch しない", async () => {
    const { handlers, emits, makeCtx } = setupExtension();

    await handlers.get("session_start")?.(
      { reason: "startup" },
      makeCtx({ provider: "openai-codex", id: "gpt-5.6-sol" }),
    );

    expect(fetchMock).not.toHaveBeenCalled();
    const update = lastUpdate(emits);
    expect(update.id).toBe("opencode-go");
    expect(update.text).toBeUndefined();
  });

  test("model_select で opencode-go から他へ切替えるとクリアしてポーリングも止まる", async () => {
    const { handlers, emits, makeCtx } = setupExtension();
    const ctx = makeCtx({ provider: "opencode-go", id: "deepseek-v4-flash" });

    await handlers.get("session_start")?.({ reason: "startup" }, ctx);
    await flush();
    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(intervals.length).toBe(1);

    // opencode-go へ戻る model_select では fetch が走る
    await handlers.get("model_select")?.(
      { model: { provider: "opencode-go", id: "deepseek-v4-flash" }, source: "set" },
      ctx,
    );
    await flush();
    expect(fetchMock).toHaveBeenCalledTimes(2);

    // 他プロバイダへ切替 → クリア + タイマー停止
    await handlers.get("model_select")?.(
      { model: { provider: "openai-codex", id: "gpt-5.6-sol" }, source: "set" },
      makeCtx({ provider: "openai-codex", id: "gpt-5.6-sol" }),
    );
    await flush();
    const update = lastUpdate(emits);
    expect(update.id).toBe("opencode-go");
    expect(update.text).toBeUndefined();
    expect(clearCalls.length).toBeGreaterThan(0);

    // タイマーコールバックが残っていても実行されない（ポーリング停止済み）
    const before = fetchMock.mock.calls.length;
    for (const fn of intervals) fn();
    expect(fetchMock.mock.calls.length).toBe(before);
  });

  test("after_provider_response（opencode-go, 200）で再フェッチされる", async () => {
    const { handlers, emits, makeCtx } = setupExtension();
    const ctx = makeCtx({ provider: "opencode-go", id: "deepseek-v4-flash" });

    await handlers.get("session_start")?.({ reason: "startup" }, ctx);
    await flush();
    const before = fetchMock.mock.calls.length;

    await handlers.get("after_provider_response")?.({ status: 200, headers: {} }, ctx);
    await flush();
    expect(fetchMock.mock.calls.length).toBe(before + 1);
    expect(emits.filter((e) => e.channel === "powerbar:update").length).toBeGreaterThan(0);
  });

  test("フェッチ失敗時は例外を投げず直前の表示を維持する", async () => {
    const { handlers, emits, makeCtx } = setupExtension();
    const ctx = makeCtx({ provider: "opencode-go", id: "deepseek-v4-flash" });

    await handlers.get("session_start")?.({ reason: "startup" }, ctx);
    await flush();
    const updateCount = emits.filter((e) => e.channel === "powerbar:update").length;
    expect(updateCount).toBeGreaterThan(0);

    fetchMock.mockImplementation(async () => {
      throw new Error("network down");
    });
    await handlers.get("after_provider_response")?.({ status: 500, headers: {} }, ctx);
    await flush();

    // 例外は投げられない。セグメントのクリアもされない（直前値を維持）
    expect(emits.filter((e) => e.channel === "powerbar:update").length).toBe(updateCount);
    expect(lastUpdate(emits).text).toContain("5h");
  });

  test("API キー未設定なら fetch せずセグメントをクリアする", async () => {
    delete process.env.OPENCODE_GO_API_KEY;
    const { handlers, emits, makeCtx } = setupExtension();

    await handlers.get("session_start")?.(
      { reason: "startup" },
      makeCtx({ provider: "opencode-go", id: "deepseek-v4-flash" }),
    );

    expect(fetchMock).not.toHaveBeenCalled();
    const update = lastUpdate(emits);
    expect(update.id).toBe("opencode-go");
    expect(update.text).toBeUndefined();
  });

  test("powerbar:register-segment が factory と session_start で emit される", async () => {
    const { handlers, emits, makeCtx } = setupExtension();

    const registrations = emits.filter((e) => e.channel === "powerbar:register-segment");
    expect(registrations.length).toBe(1);
    expect(registrations[0].data).toEqual({ id: "opencode-go", label: "OpenCode Go" });

    await handlers.get("session_start")?.(
      { reason: "startup" },
      makeCtx({ provider: "opencode-go", id: "deepseek-v4-flash" }),
    );
    expect(
      emits.filter((e) => e.channel === "powerbar:register-segment").length,
    ).toBe(2);
  });
});
