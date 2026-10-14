/**
 * Jev Routed Segment - powerbar producer
 *
 * powerbar replaces the built-in footer (`ctx.ui.setFooter` with an empty renderer; see
 * opencode-go-rate-limit.ts for the same reason), so Pi's built-in `→ <physical model>`
 * routing display is hidden while powerbar is active. This extension re-exposes the routed
 * physical model as a powerbar segment, in the same format as the built-in footer.
 *
 * The powerbar `model` segment shows the selected model (`ctx.model.id`, e.g. `auto`) and the
 * `provider` segment shows `ctx.model.provider` (e.g. `jev`). Neither consults the routed
 * physical model, so a virtual model's dispatch target is otherwise invisible.
 *
 * Segment ID: "routed". Add `routed` to the powerbar `right` list in
 * conf/.pi/agent/settings-extensions.json to show it. Values come from the latest successful
 * assistant response on the session branch. The segment is cleared when the selected model is
 * not a virtual model.
 */

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

export const SEGMENT_ID = "routed";
const SEGMENT_LABEL = "Routed";
const SEGMENT_COLOR = "dim";
/** `api` of virtual catalog entries. Mirrors VIRTUAL_MODEL_API in Pi core. */
const VIRTUAL_MODEL_API = "pi-virtual";

export interface RoutedResponse {
  model: string;
  thinkingLevel?: string;
}

/** Whether the selected model is a virtual model, i.e. it routes each request to a physical one. */
export function isVirtualSelection(ctx: ExtensionContext): boolean {
  return ctx.model?.api === VIRTUAL_MODEL_API;
}

/** Latest successful assistant response on the current branch, ignoring failed or aborted ones. */
export function latestResponse(ctx: ExtensionContext): RoutedResponse | undefined {
  const branch = ctx.sessionManager.getBranch();
  for (let i = branch.length - 1; i >= 0; i--) {
    const entry = branch[i];
    if (entry.type !== "message") continue;
    const message = entry.message;
    if (message.role !== "assistant") continue;
    if (message.stopReason === "error" || message.stopReason === "aborted") continue;
    return { model: message.model, thinkingLevel: message.thinkingLevel };
  }
  return undefined;
}

/** Payload for the `routed` segment, or undefined when there is nothing to show. */
export function buildSegmentPayload(
  response?: RoutedResponse,
): { text: string; color: string } | undefined {
  if (!response?.model) return undefined;
  const level = response.thinkingLevel ? ` · ${response.thinkingLevel}` : "";
  return { text: `→ ${response.model}${level}`, color: SEGMENT_COLOR };
}

function registerSegment(pi: ExtensionAPI): void {
  pi.events.emit("powerbar:register-segment", { id: SEGMENT_ID, label: SEGMENT_LABEL });
}

function clearSegment(pi: ExtensionAPI): void {
  pi.events.emit("powerbar:update", { id: SEGMENT_ID, text: undefined });
}

function emit(pi: ExtensionAPI, ctx: ExtensionContext, response?: RoutedResponse): void {
  if (!ctx.hasUI || !isVirtualSelection(ctx)) {
    clearSegment(pi);
    return;
  }
  const payload = buildSegmentPayload(response ?? latestResponse(ctx));
  if (!payload) {
    clearSegment(pi);
    return;
  }
  pi.events.emit("powerbar:update", { id: SEGMENT_ID, ...payload });
}

export default function createExtension(pi: ExtensionAPI): void {
  // powerbar may load after this extension; register at factory time too (same as opencode-go-rate-limit).
  registerSegment(pi);

  pi.on("session_start", (_event, ctx) => {
    emit(pi, ctx);
  });

  pi.on("model_select", (_event, ctx) => {
    emit(pi, ctx);
  });

  pi.on("message_end", (event, ctx) => {
    if (event.message.role !== "assistant") return;
    emit(pi, ctx, {
      model: event.message.model,
      thinkingLevel: event.message.thinkingLevel,
    });
  });
}
