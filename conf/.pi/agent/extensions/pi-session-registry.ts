import { mkdir, rm, writeFile } from "node:fs/promises";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const REGISTRY_DIR = "/tmp/pi-sessions";
const REGISTRY_FILE = `${REGISTRY_DIR}/${process.pid}`;

export default function registerPiSession(pi: ExtensionAPI) {
  pi.on("session_start", async (_event, ctx) => {
    const sessionId = ctx.sessionManager.getSessionId();
    if (!sessionId) return;

    await mkdir(REGISTRY_DIR, { recursive: true, mode: 0o700 });
    await writeFile(REGISTRY_FILE, `${sessionId}\n`, { mode: 0o600 });
  });

  pi.on("session_shutdown", async () => {
    await rm(REGISTRY_FILE, { force: true });
  });
}
