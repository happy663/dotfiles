import { describe, expect, test } from "bun:test";

const {
  default: createExtension,
  SEGMENT_ID,
  isVirtualSelection,
  latestResponse,
  buildSegmentPayload,
} = await import("../extensions/jev-routed-segment.ts");

type Handler = (event: any, ctx: any) => Promise<void> | void;

const VIRTUAL_MODEL = { provider: "jev", id: "auto", api: "pi-virtual" };
const PHYSICAL_MODEL = { provider: "openai-codex", id: "gpt-5.6-sol", api: "openai-responses" };

function assistantEntry(model: string, thinkingLevel?: string, stopReason = "stop") {
  return {
    type: "message",
    message: { role: "assistant", provider: "openai-codex", model, thinkingLevel, stopReason },
  };
}

function makeCtx(options: { model?: any; branch?: any[]; hasUI?: boolean } = {}): any {
  // `model: undefined` を明示した場合と、未指定を区別する
  const model = "model" in options ? options.model : VIRTUAL_MODEL;
  return {
    hasUI: options.hasUI ?? true,
    model,
    sessionManager: { getBranch: () => options.branch ?? [] },
  };
}

function setupExtension() {
  const handlers = new Map<string, Handler>();
  const emits: Array<{ channel: string; data: any }> = [];
  const pi = {
    on: (event: string, handler: Handler) => handlers.set(event, handler),
    events: {
      emit: (channel: string, data: unknown) => emits.push({ channel, data }),
      on: () => () => {},
    },
  };

  createExtension(pi as any);

  const updates = (): any[] =>
    emits.filter((e) => e.channel === "powerbar:update").map((e) => e.data);
  const lastUpdate = (): any => updates().at(-1);

  return { handlers, emits, updates, lastUpdate };
}

describe("isVirtualSelection", () => {
  test("virtual model のときだけ true", () => {
    expect(isVirtualSelection(makeCtx({ model: VIRTUAL_MODEL }))).toBe(true);
    expect(isVirtualSelection(makeCtx({ model: PHYSICAL_MODEL }))).toBe(false);
    expect(isVirtualSelection(makeCtx({ model: undefined }))).toBe(false);
  });
});

describe("latestResponse", () => {
  test("最新の成功した assistant メッセージの model と thinkingLevel を返す", () => {
    const ctx = makeCtx({
      branch: [
        assistantEntry("gpt-5.6-terra", "medium"),
        { type: "message", message: { role: "user", content: "hi" } },
        assistantEntry("gpt-5.6-luna", "low"),
      ],
    });

    expect(latestResponse(ctx)).toEqual({ model: "gpt-5.6-luna", thinkingLevel: "low" });
  });

  test("error / aborted のレスポンスはスキップする", () => {
    const ctx = makeCtx({
      branch: [
        assistantEntry("gpt-5.6-sol", "high"),
        assistantEntry("gpt-5.6-luna", "low", "aborted"),
        assistantEntry("gpt-5.6-terra", "medium", "error"),
      ],
    });

    expect(latestResponse(ctx)).toEqual({ model: "gpt-5.6-sol", thinkingLevel: "high" });
  });

  test("assistant メッセージが無ければ undefined", () => {
    expect(latestResponse(makeCtx({ branch: [] }))).toBeUndefined();
  });
});

describe("buildSegmentPayload", () => {
  test("thinking level 付きのテキストを組み立てる", () => {
    expect(buildSegmentPayload({ model: "gpt-5.6-sol", thinkingLevel: "high" })).toEqual({
      text: "→ gpt-5.6-sol · high",
      color: "dim",
    });
  });

  test("thinking level が無ければモデル名だけ", () => {
    expect(buildSegmentPayload({ model: "gpt-5.6-terra" })).toEqual({
      text: "→ gpt-5.6-terra",
      color: "dim",
    });
  });

  test("レスポンスが無ければ undefined", () => {
    expect(buildSegmentPayload(undefined)).toBeUndefined();
  });
});

describe("extension wiring", () => {
  test("factory 時にセグメントを登録する", () => {
    const { emits } = setupExtension();
    expect(emits[0]).toEqual({
      channel: "powerbar:register-segment",
      data: { id: SEGMENT_ID, label: "Routed" },
    });
  });

  test("virtual model 選択時は routed を表示する", () => {
    const { handlers, lastUpdate } = setupExtension();
    const ctx = makeCtx({ branch: [assistantEntry("gpt-5.6-sol", "high")] });

    handlers.get("model_select")?.({}, ctx);

    expect(lastUpdate()).toEqual({ id: SEGMENT_ID, text: "→ gpt-5.6-sol · high", color: "dim" });
  });

  test("physical model 選択時は routed をクリアする", () => {
    const { handlers, lastUpdate } = setupExtension();

    handlers.get("model_select")?.({}, makeCtx({ model: PHYSICAL_MODEL }));

    expect(lastUpdate()).toEqual({ id: SEGMENT_ID, text: undefined });
  });

  test("UI が無いときは routed をクリアする", () => {
    const { handlers, lastUpdate } = setupExtension();

    handlers.get("model_select")?.({}, makeCtx({ hasUI: false }));

    expect(lastUpdate()).toEqual({ id: SEGMENT_ID, text: undefined });
  });

  test("assistant の message_end で routed を更新する", () => {
    const { handlers, lastUpdate } = setupExtension();

    handlers.get("message_end")?.(
      { message: { role: "assistant", model: "gpt-5.6-luna", thinkingLevel: "low" } },
      makeCtx(),
    );

    expect(lastUpdate()).toEqual({ id: SEGMENT_ID, text: "→ gpt-5.6-luna · low", color: "dim" });
  });

  test("assistant 以外の message_end では更新しない", () => {
    const { handlers, updates } = setupExtension();

    handlers.get("message_end")?.({ message: { role: "toolResult", toolName: "read" } }, makeCtx());

    expect(updates()).toHaveLength(0);
  });
});
