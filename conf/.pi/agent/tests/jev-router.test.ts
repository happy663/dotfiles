import { describe, expect, test } from "bun:test";

const { default: createExtension } = await import("../extensions/jev-router.ts");

const COMPLEX = {
  stopReason: "stop",
  answers: {
    complexity: {
      type: "choice",
      choice: "complex",
      probabilities: { standard: 0.1, complex: 0.9 },
    },
  },
};

const STANDARD = {
  stopReason: "stop",
  answers: {
    complexity: {
      type: "choice",
      choice: "standard",
      probabilities: { standard: 0.9, complex: 0.1 },
    },
  },
};

const CLASSIFY_ERROR = { stopReason: "error", answers: {} };

const MODELS: Record<string, any> = {
  "openai-codex/gpt-5.6-sol": { provider: "openai-codex", id: "gpt-5.6-sol" },
  "openai-codex/gpt-5.6-terra": { provider: "openai-codex", id: "gpt-5.6-terra" },
  "openai-codex/gpt-5.6-luna": { provider: "openai-codex", id: "gpt-5.6-luna" },
};

interface SetupOptions {
  jev?: boolean;
  classifyResult?: any;
}

function setup({ jev = true, classifyResult = COMPLEX }: SetupOptions = {}) {
  let definition: any;
  const pi = {
    registerVirtualModel: (d: any) => {
      definition = d;
    },
  };
  createExtension(pi as any);

  const classifyCalls: any[] = [];
  const ctx = {
    modelRegistry: {
      find: (provider: string, id: string) => MODELS[`${provider}/${id}`],
      findOfType: (type: string, provider: string, id: string) =>
        jev ? { type, provider, id } : undefined,
      classify: async (_model: any, context: any, _options: any) => {
        classifyCalls.push(context);
        return classifyResult;
      },
    },
  };

  return { definition, ctx, classifyCalls };
}

function makeRequest(overrides: any = {}): any {
  return {
    reason: "user",
    thinkingLevel: "medium",
    previous: undefined,
    messages: [{ role: "user", content: "do something" }],
    signal: undefined,
    ...overrides,
  };
}

/** messages の最後の user 以降に、成功した edit が含まれる状態を作る。 */
function messagesWithEdit(): any[] {
  return [
    { role: "user", content: "edit test.txt" },
    { role: "assistant", content: [{ type: "tool_use", name: "edit" }] },
    { role: "toolResult", toolName: "edit", isError: false, content: [] },
  ];
}

describe("jev-router (per-turn reclassification)", () => {
  test("最初の user ターンで complex なら sol を計画モデルにする", async () => {
    const { definition, ctx } = setup({ classifyResult: COMPLEX });

    const route = await definition.route(makeRequest(), ctx);

    expect(route.model.id).toBe("gpt-5.6-sol");
    expect(route.state).toEqual({ phase: "planning", model: "gpt-5.6-sol" });
  });

  test("最初の user ターンで standard なら terra を計画モデルにする", async () => {
    const { definition, ctx } = setup({ classifyResult: STANDARD });

    const route = await definition.route(makeRequest(), ctx);

    expect(route.model.id).toBe("gpt-5.6-terra");
    expect(route.state).toEqual({ phase: "planning", model: "gpt-5.6-terra" });
  });

  test("新しい user ターンでは implementation 状態でも再分類する", async () => {
    const { definition, ctx } = setup({ classifyResult: COMPLEX });

    const route = await definition.route(
      makeRequest({ state: { phase: "implementation", model: "gpt-5.6-luna" } }),
      ctx,
    );

    expect(route.model.id).toBe("gpt-5.6-sol");
    expect(route.state).toEqual({ phase: "planning", model: "gpt-5.6-sol" });
  });

  test("user ターンでは previous の planning モデルに引きずられず毎回 Jev を呼ぶ", async () => {
    const { definition, ctx, classifyCalls } = setup({ classifyResult: COMPLEX });

    const route = await definition.route(
      makeRequest({
        previous: { model: { provider: "openai-codex", id: "gpt-5.6-terra" }, thinkingLevel: "medium" },
      }),
      ctx,
    );

    expect(classifyCalls).toHaveLength(1);
    expect(route.model.id).toBe("gpt-5.6-sol");
  });

  test("continuation は state のモデルに固定する", async () => {
    const { definition, ctx, classifyCalls } = setup();

    const route = await definition.route(
      makeRequest({ reason: "continuation", state: { phase: "planning", model: "gpt-5.6-terra" } }),
      ctx,
    );

    expect(classifyCalls).toHaveLength(0);
    expect(route.model.id).toBe("gpt-5.6-terra");
    expect(route.state).toBeUndefined();
  });

  test("計画フェーズで最初の edit が成功したら luna へ切り替える", async () => {
    const { definition, ctx, classifyCalls } = setup();

    const route = await definition.route(
      makeRequest({
        reason: "continuation",
        state: { phase: "planning", model: "gpt-5.6-terra" },
        messages: messagesWithEdit(),
      }),
      ctx,
    );

    expect(classifyCalls).toHaveLength(0);
    expect(route.model.id).toBe("gpt-5.6-luna");
    expect(route.state).toEqual({ phase: "implementation", model: "gpt-5.6-luna" });
  });

  test("実装フェーズの continuation は luna を維持する", async () => {
    const { definition, ctx } = setup();

    const route = await definition.route(
      makeRequest({
        reason: "continuation",
        state: { phase: "implementation", model: "gpt-5.6-luna" },
        messages: messagesWithEdit(),
      }),
      ctx,
    );

    expect(route.model.id).toBe("gpt-5.6-luna");
    expect(route.state).toBeUndefined();
  });

  test("state が無い continuation は分類して計画フェーズを開始する", async () => {
    const { definition, ctx } = setup({ classifyResult: STANDARD });

    const route = await definition.route(makeRequest({ reason: "continuation" }), ctx);

    expect(route.model.id).toBe("gpt-5.6-terra");
    expect(route.state).toEqual({ phase: "planning", model: "gpt-5.6-terra" });
  });

  test("direct は luna に固定する", async () => {
    const { definition, ctx, classifyCalls } = setup();

    const route = await definition.route(
      makeRequest({ reason: "direct", state: { phase: "implementation", model: "gpt-5.6-luna" } }),
      ctx,
    );

    expect(classifyCalls).toHaveLength(0);
    expect(route.model.id).toBe("gpt-5.6-luna");
  });

  test("Jev が使えないときは previous の planning モデルへフォールバックする", async () => {
    const { definition, ctx, classifyCalls } = setup({
      jev: false,
    });

    const route = await definition.route(
      makeRequest({
        previous: { model: { provider: "openai-codex", id: "gpt-5.6-sol" }, thinkingLevel: "medium" },
      }),
      ctx,
    );

    expect(classifyCalls).toHaveLength(0);
    expect(route.model.id).toBe("gpt-5.6-sol");
  });

  test("Jev が使えず previous も無いときは terra にフォールバックする", async () => {
    const { definition, ctx } = setup({ jev: false });

    const route = await definition.route(makeRequest(), ctx);

    expect(route.model.id).toBe("gpt-5.6-terra");
  });

  test("分類が失敗したときは previous の planning モデルへフォールバックする", async () => {
    const { definition, ctx } = setup({ classifyResult: CLASSIFY_ERROR });

    const route = await definition.route(
      makeRequest({
        previous: { model: { provider: "openai-codex", id: "gpt-5.6-terra" }, thinkingLevel: "medium" },
      }),
      ctx,
    );

    expect(route.model.id).toBe("gpt-5.6-terra");
  });

  test("分類が失敗し previous が実装モデルなら terra にフォールバックする", async () => {
    const { definition, ctx } = setup({ classifyResult: CLASSIFY_ERROR });

    const route = await definition.route(
      makeRequest({
        previous: { model: { provider: "openai-codex", id: "gpt-5.6-luna" }, thinkingLevel: "medium" },
      }),
      ctx,
    );

    expect(route.model.id).toBe("gpt-5.6-terra");
  });
});
