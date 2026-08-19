import type {
  ExtensionAPI,
  ExtensionContext,
  ModelSelectEvent,
} from "@earendil-works/pi-coding-agent";

/**
 * OpenCode Go rate-limit / quota statusline extension.
 *
 * Polls the (undocumented) usage endpoint `GET https://opencode.ai/zen/go/v1/usage`
 * with the same Bearer key the provider uses ($OPENCODE_GO_API_KEY) and shows the
 * remaining quota of each spend-based window (5h=$12 / weekly=$30 / monthly=$60)
 * as a segment in the pi-powerbar statusline.
 *
 * The statusline is owned by `@juanibiapina/pi-powerbar`, which replaces the
 * built-in footer. Instead of `ctx.ui.setStatus()` (invisible under powerbar),
 * this extension registers and updates a powerbar segment via the
 * `powerbar:register-segment` / `powerbar:update` events — the same pattern as
 * the bundled `powerbar-sub` producer.
 *
 * The endpoint is not officially documented, so parsing is defensive: on any
 * fetch/parse failure we keep the last known values and never throw.
 */

export const SEGMENT_ID = "opencode-go";
export const USAGE_URL = "https://opencode.ai/zen/go/v1/usage";
export const POLL_INTERVAL_MS = 60_000;
export const BAR_SEGMENTS = 10;

export interface GoUsageWindow {
  key: "rolling" | "weekly" | "monthly";
  label: string;
  status: string;
  percent: number;
  resetsAt?: number;
}

export interface GoUsage {
  windows: GoUsageWindow[];
}

export interface SegmentPayload {
  text: string;
  bar: number;
  suffix?: string;
  color: string;
}

const WINDOW_DEFS = [
  { key: "rolling", label: "5h" },
  { key: "weekly", label: "wk" },
  { key: "monthly", label: "mo" },
] as const;

const WINDOW_PRIORITY: Record<string, number> = {
  rolling: 0,
  weekly: 1,
  monthly: 2,
};

function normalizeWindow(
  key: GoUsageWindow["key"],
  label: string,
  raw: unknown,
  now: number,
): GoUsageWindow | undefined {
  if (!raw || typeof raw !== "object" || Array.isArray(raw)) return undefined;
  const r = raw as Record<string, unknown>;

  let percent: number | undefined;
  const rawPercent = r.percent ?? r.usagePercent;
  if (typeof rawPercent === "number" && Number.isFinite(rawPercent)) {
    percent = rawPercent;
  } else if (
    typeof rawPercent === "string" &&
    rawPercent.trim() !== "" &&
    Number.isFinite(Number(rawPercent))
  ) {
    percent = Number(rawPercent);
  }
  if (percent === undefined) return undefined;

  const status = typeof r.status === "string" && r.status !== "" ? r.status : "ok";

  let resetsAt: number | undefined;
  if (typeof r.resetsAt === "string") {
    const t = Date.parse(r.resetsAt);
    if (!Number.isNaN(t)) resetsAt = t;
  } else if (
    typeof r.resetsInSeconds === "number" &&
    Number.isFinite(r.resetsInSeconds)
  ) {
    resetsAt = now + r.resetsInSeconds * 1000;
  }

  return {
    key,
    label,
    status,
    percent: Math.max(0, Math.min(100, Math.round(percent))),
    resetsAt,
  };
}

/** 実測スキーマ `usage.{rolling,weekly,monthly}` + 別スキーマ（usagePercent/resetsInSeconds、トップレベル直下）を防御的にパースする。 */
export function parseUsageResponse(
  json: unknown,
  now: number = Date.now(),
): GoUsage | undefined {
  if (!json || typeof json !== "object" || Array.isArray(json)) return undefined;
  const root = json as Record<string, unknown>;

  const container =
    root.usage && typeof root.usage === "object" && !Array.isArray(root.usage)
      ? (root.usage as Record<string, unknown>)
      : root;

  const windows: GoUsageWindow[] = [];
  for (const def of WINDOW_DEFS) {
    const w = normalizeWindow(def.key, def.label, container[def.key], now);
    if (w) windows.push(w);
  }
  return windows.length > 0 ? { windows } : undefined;
}

/** percent 最大の窓（同率なら 5h > wk > mo）。 */
export function pickCritical(usage: GoUsage): GoUsageWindow | undefined {
  if (usage.windows.length === 0) return undefined;
  return [...usage.windows].sort((a, b) => {
    if (b.percent !== a.percent) return b.percent - a.percent;
    return (WINDOW_PRIORITY[a.key] ?? 9) - (WINDOW_PRIORITY[b.key] ?? 9);
  })[0];
}

export function colorForPercent(pct: number, limited: boolean): string {
  if (limited || pct >= 80) return "error";
  if (pct >= 50) return "warning";
  return "success";
}

export function formatReset(resetsAt: number, now: number = Date.now()): string {
  const diffMs = resetsAt - now;
  if (diffMs <= 0) return "now";
  const totalMin = Math.max(1, Math.ceil(diffMs / 60_000));
  if (totalMin < 60) return `${totalMin}m`;
  const hours = Math.floor(totalMin / 60);
  const mins = totalMin % 60;
  if (hours < 24) return mins > 0 ? `${hours}h${mins}m` : `${hours}h`;
  const days = Math.floor(hours / 24);
  const remHours = hours % 24;
  return remHours > 0 ? `${days}d ${remHours}h` : `${days}d`;
}

/** powerbar セグメントのペイロードを組み立てる。有効な窓が無ければ undefined。 */
export function buildSegmentPayload(
  usage: GoUsage,
  now: number = Date.now(),
): SegmentPayload | undefined {
  if (usage.windows.length === 0) return undefined;

  const critical = pickCritical(usage);
  if (!critical) return undefined;

  const maxPct = Math.max(...usage.windows.map((w) => w.percent));
  const limited = usage.windows.some((w) => w.status !== "ok");

  const text = usage.windows.map((w) => `${w.label} ${w.percent}%`).join(" · ");

  let suffix: string | undefined;
  if (limited) {
    suffix = `! ${critical.label} limit`;
    if (critical.resetsAt !== undefined) {
      suffix += ` (reset ${formatReset(critical.resetsAt, now)})`;
    }
  } else if (critical.resetsAt !== undefined) {
    suffix = `reset ${formatReset(critical.resetsAt, now)}`;
  }

  return {
    text,
    bar: critical.percent,
    suffix,
    color: colorForPercent(maxPct, limited),
  };
}

export default function createExtension(pi: ExtensionAPI): void {
  let timer: ReturnType<typeof setInterval> | undefined;
  let active = false;

  function registerSegment(): void {
    pi.events.emit("powerbar:register-segment", {
      id: SEGMENT_ID,
      label: "OpenCode Go",
    });
  }

  function clearSegment(): void {
    pi.events.emit("powerbar:update", { id: SEGMENT_ID, text: undefined });
  }

  function emitUpdate(payload: SegmentPayload): void {
    pi.events.emit("powerbar:update", {
      id: SEGMENT_ID,
      ...payload,
      barSegments: BAR_SEGMENTS,
    });
  }

  async function refresh(): Promise<void> {
    if (!active) return;

    const apiKey = process.env.OPENCODE_GO_API_KEY;
    if (!apiKey) {
      clearSegment();
      return;
    }

    try {
      const res = await fetch(USAGE_URL, {
        headers: { Authorization: `Bearer ${apiKey}` },
        signal: AbortSignal.timeout(10_000),
      });
      if (!res.ok) return; // 直前の表示を維持

      const json: unknown = await res.json();
      const usage = parseUsageResponse(json);
      const payload = usage ? buildSegmentPayload(usage) : undefined;
      if (payload && active) {
        emitUpdate(payload);
      }
      // パース失敗時は直前の表示を維持（クリアしない）
    } catch {
      // ネットワーク断等でも例外を投げず、直前の表示を維持する
    }
  }

  function startPolling(): void {
    stopPolling();
    registerSegment();
    void refresh();
    const id = setInterval(() => {
      // 停止後に古いコールバックが走っても fetch しない
      if (timer === id) void refresh();
    }, POLL_INTERVAL_MS);
    timer = id;
  }

  function stopPolling(): void {
    if (timer !== undefined) {
      clearInterval(timer);
      timer = undefined;
    }
  }

  function isOpenCodeGo(ctx: ExtensionContext): boolean {
    return ctx.model?.provider === SEGMENT_ID;
  }

  function handleModel(modelProvider: string, ctx: ExtensionContext): void {
    if (ctx.hasUI && modelProvider === SEGMENT_ID) {
      active = true;
      startPolling();
    } else {
      active = false;
      stopPolling();
      clearSegment();
    }
  }

  // powerbar がこの拡張より後にロードされた場合に備え、factory 時にも登録する
  registerSegment();

  pi.on("session_start", (_event, ctx) => {
    if (ctx.hasUI && isOpenCodeGo(ctx)) {
      active = true;
      startPolling();
    } else {
      active = false;
      stopPolling();
      clearSegment();
    }
  });

  pi.on("model_select", (event: ModelSelectEvent, ctx) => {
    handleModel(event.model.provider, ctx);
  });

  pi.on("after_provider_response", (_event, ctx) => {
    if (ctx.hasUI && isOpenCodeGo(ctx)) {
      void refresh();
    }
  });

  pi.on("session_shutdown", () => {
    active = false;
    stopPolling();
    clearSegment();
  });
}
