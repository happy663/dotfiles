import { beforeEach, describe, expect, mock, test } from "bun:test";

const setDefaultCalls: Array<{ provider: string; modelId: string }> = [];
let globalSettings: { defaultProvider?: string; defaultModel?: string } = {};

const flush = mock(async () => {});
const notify = mock(() => {});

mock.module("@earendil-works/pi-coding-agent", () => ({
  getAgentDir: () => "/tmp/pi-agent",
  SettingsManager: {
    create: () => ({
      getGlobalSettings: () => ({ ...globalSettings }),
      setDefaultModelAndProvider: (provider: string, modelId: string) => {
        setDefaultCalls.push({ provider, modelId });
      },
      flush,
      drainErrors: () => [],
    }),
  },
}));

const { default: keepDefaultModel } = await import(
  "../../conf/.pi/agent/extensions/keep-default-model.ts"
);

type Handler = (event: any, ctx: any) => Promise<void> | void;

function setupExtension() {
  const handlers = new Map<string, Handler>();
  keepDefaultModel({
    on: (event: string, handler: Handler) => handlers.set(event, handler),
  } as any);

  const ctx = {
    cwd: "/tmp/project",
    isProjectTrusted: () => true,
    model: { provider: "openai-codex", id: "gpt-5.6-sol" },
    ui: { notify },
  };

  return { handlers, ctx };
}

describe("keep-default-model extension", () => {
  beforeEach(() => {
    globalSettings = {
      defaultProvider: "openai-codex",
      defaultModel: "gpt-5.6-sol",
    };
    setDefaultCalls.length = 0;
    flush.mockClear();
    notify.mockClear();
  });

  test("Ctrl+PとCtrl+Shift+Pに共通するcycleイベント後に既定モデルを復元する", async () => {
    const { handlers, ctx } = setupExtension();

    await handlers.get("model_select")?.(
      {
        source: "cycle",
        model: { provider: "opencode-go", id: "deepseek-v4-flash" },
      },
      ctx,
    );

    expect(setDefaultCalls).toEqual([
      { provider: "openai-codex", modelId: "gpt-5.6-sol" },
    ]);
    expect(flush).toHaveBeenCalledTimes(1);
  });

  test("明示的なモデル選択は新しい既定値として次のcycle後に復元する", async () => {
    const { handlers, ctx } = setupExtension();
    const modelSelect = handlers.get("model_select");

    await modelSelect?.(
      {
        source: "set",
        model: { provider: "anthropic", id: "claude-sonnet-4-5" },
      },
      ctx,
    );
    await modelSelect?.(
      {
        source: "cycle",
        model: { provider: "opencode-go", id: "deepseek-v4-flash" },
      },
      ctx,
    );

    expect(setDefaultCalls).toEqual([
      { provider: "anthropic", modelId: "claude-sonnet-4-5" },
    ]);
  });

  test("セッション復元では既定モデルを書き換えない", async () => {
    const { handlers, ctx } = setupExtension();

    await handlers.get("model_select")?.(
      {
        source: "restore",
        model: { provider: "opencode-go", id: "deepseek-v4-flash" },
      },
      ctx,
    );

    expect(setDefaultCalls).toEqual([]);
  });
});
