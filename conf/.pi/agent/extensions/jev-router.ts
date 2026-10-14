/**
 * Jev router - a virtual model that plans on a strong model and implements on a cheap one.
 *
 * Vendored from pi 0.99.2 `examples/extensions/jev-router.ts` and adapted for dotfiles.
 * Local TypeScript extensions are auto-loaded from `~/.pi/agent/extensions/`, so there is no
 * need to pass `-e`. Select the model with `/model` (listed as `jev/auto`) or `--model jev/auto`.
 *
 * Registers `jev/auto`, which routes between three OpenAI Codex models:
 *
 * - Planning: GPT-5.6 Sol for complex work, GPT-5.6 Terra otherwise. The Jev classifier rates the
 *   latest user message on every user turn, so a vague first prompt does not pin the session's
 *   planning model.
 * - Implementation: GPT-5.6 Luna.
 *
 * The planning model explores, plans, and makes the first edit. After the first successful `edit`
 * or `write` tool call, the next request of the same turn goes to Luna. The next user turn starts
 * a fresh planning phase, so each task is classified again. Continuations and retries stay on the
 * current model to keep the prompt cache; only a turn whose classified model changes pays a cache
 * miss.
 *
 * The phase is router state: Pi stores it on the session branch, so it follows the session tree
 * and survives compaction. The selected thinking level passes through as the reasoning effort of
 * the chosen model. Requests outside the agent loop, such as compaction summaries, go to Luna.
 *
 * Requires TypeSafe credentials (TYPESAFE_API_KEY, set in the dotfiles .env) and an OpenAI Codex
 * login. When Jev is unavailable or a classification fails, planning falls back to the planning
 * model the session already uses (Sol or Terra), or Terra, so routing still works.
 */

import type { Message } from "@earendil-works/pi-ai";
import type {
  ExtensionAPI,
  ExtensionContext,
  ModelRoute,
  ModelRouteRequest,
} from "@earendil-works/pi-coding-agent";

const PROVIDER = "openai-codex";
const SOL = "gpt-5.6-sol";
const TERRA = "gpt-5.6-terra";
const LUNA = "gpt-5.6-luna";

/** Tools whose successful result means implementation has started. */
const EDIT_TOOLS = new Set(["edit", "write"]);

interface JevState {
  phase: "planning" | "implementation";
  /** OpenAI Codex model for this phase. */
  model: string;
}

type JevRequest = ModelRouteRequest<JevState>;

function routeTo(
  request: JevRequest,
  ctx: ExtensionContext,
  id: string,
  state?: JevState,
): ModelRoute<JevState> {
  const model = ctx.modelRegistry.find(PROVIDER, id);
  if (!model) throw new Error(`Model ${PROVIDER}/${id} is not in the catalog`);
  return { model, thinkingLevel: request.thinkingLevel, state };
}

function lastUserText(messages: readonly Message[]): string {
  const content =
    messages.filter((message) => message.role === "user").at(-1)?.content ?? "";
  if (typeof content === "string") return content;
  return content.flatMap((block) => (block.type === "text" ? [block.text] : [])).join("\n");
}

/** Whether a tool call since the last user message edited a file successfully. */
function editedThisTurn(messages: readonly Message[]): boolean {
  const lastUser = messages.findLastIndex((message) => message.role === "user");
  return messages
    .slice(lastUser + 1)
    .some(
      (message) =>
        message.role === "toolResult" && EDIT_TOOLS.has(message.toolName) && !message.isError,
    );
}

/** Planning model for a user turn: complex work goes to Sol, otherwise Terra. */
async function choosePlanningModel(
  request: JevRequest,
  ctx: ExtensionContext,
): Promise<string> {
  const jev = ctx.modelRegistry.findOfType("classifier", "typesafe", "jev-latest");
  if (!jev) return fallbackPlanningModel(request);

  const result = await ctx.modelRegistry.classify(
    jev,
    {
      state: { prompt: lastUserText(request.messages).slice(0, 16_000) },
      questions: {
        complexity: {
          type: "choice",
          instructions:
            "How demanding is the software engineering work requested in `prompt`?",
          criteria: {
            standard: "Ordinary features, fixes, reviews, or questions",
            complex: "Subtle design, cross-cutting changes, or hard debugging",
          },
        },
      },
    },
    { signal: request.signal },
  );
  const answer = result.stopReason === "stop" ? result.answers.complexity : undefined;
  if (answer?.type !== "choice") return fallbackPlanningModel(request);
  return (answer.probabilities.complex ?? 0) >= 0.5 ? SOL : TERRA;
}

/** When Jev is unavailable, keep a planning model the session already uses to avoid a cache miss. */
function fallbackPlanningModel(request: JevRequest): string {
  const previous = request.previous?.model;
  if (previous?.provider === PROVIDER && (previous.id === SOL || previous.id === TERRA)) {
    return previous.id;
  }
  return TERRA;
}

export default function (pi: ExtensionAPI) {
  pi.registerVirtualModel<JevState>({
    provider: "jev",
    id: "auto",
    name: "Auto (Jev)",
    thinkingLevels: ["low", "medium", "high", "xhigh"],
    // Shared by all three models; shown before the first response.
    contextWindow: 272_000,
    maxTokens: 128_000,
    async route(request, ctx) {
      if (request.reason === "direct") return routeTo(request, ctx, LUNA);

      const state = request.state;
      // Re-classify on every user turn, so a vague first prompt does not pin the planning model.
      if (request.reason === "user" || !state) {
        const model = await choosePlanningModel(request, ctx);
        return routeTo(request, ctx, model, { phase: "planning", model });
      }
      // The planning model made the first edit: hand the rest of the work to Luna.
      if (state.phase === "planning" && editedThisTurn(request.messages)) {
        return routeTo(request, ctx, LUNA, { phase: "implementation", model: LUNA });
      }
      return routeTo(request, ctx, state.model);
    },
  });
}
