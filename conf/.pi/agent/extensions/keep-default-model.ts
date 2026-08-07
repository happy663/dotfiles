import {
  type ExtensionAPI,
  getAgentDir,
  SettingsManager,
} from "@earendil-works/pi-coding-agent";

type DefaultModel = {
  provider: string;
  modelId: string;
};

function readGlobalDefault(
  settings: SettingsManager,
): DefaultModel | undefined {
  const globalSettings = settings.getGlobalSettings();
  const provider = globalSettings.defaultProvider;
  const modelId = globalSettings.defaultModel;

  if (!provider || !modelId) return undefined;
  return { provider, modelId };
}

function waitForBuiltInSettingsWrites(): Promise<void> {
  return new Promise((resolve) => setImmediate(resolve));
}

export default function (pi: ExtensionAPI) {
  const agentDir = getAgentDir();
  let persistentDefault = readGlobalDefault(
    SettingsManager.create(process.cwd(), agentDir),
  );

  pi.on("session_start", (_event, ctx) => {
    if (!persistentDefault && ctx.model) {
      persistentDefault = {
        provider: ctx.model.provider,
        modelId: ctx.model.id,
      };
    }
  });

  pi.on("model_select", async (event, ctx) => {
    if (event.source === "set") {
      persistentDefault = {
        provider: event.model.provider,
        modelId: event.model.id,
      };
      return;
    }

    if (event.source !== "cycle" || !persistentDefault) return;

    if (
      event.model.provider === persistentDefault.provider &&
      event.model.id === persistentDefault.modelId
    ) {
      return;
    }

    try {
      // AgentSessionの非同期設定保存が完了してから、既定値だけを復元する。
      await waitForBuiltInSettingsWrites();

      const settings = SettingsManager.create(ctx.cwd, agentDir, {
        projectTrusted: ctx.isProjectTrusted(),
      });
      settings.setDefaultModelAndProvider(
        persistentDefault.provider,
        persistentDefault.modelId,
      );
      await settings.flush();

      const errors = settings.drainErrors();
      if (errors.length > 0) {
        throw errors[0].error;
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      ctx.ui.notify(`Failed to restore default model: ${message}`, "error");
    }
  });
}
