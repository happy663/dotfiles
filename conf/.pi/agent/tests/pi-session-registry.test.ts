import { afterEach, describe, expect, test } from "bun:test";
import { readFile, rm } from "node:fs/promises";

import registerPiSession from "../extensions/pi-session-registry";

const registryFile = `/tmp/pi-sessions/${process.pid}`;

type Handler = (event: unknown, ctx: unknown) => Promise<void> | void;

const handlers = new Map<string, Handler>();
const pi = {
  on(event: string, handler: Handler) {
    handlers.set(event, handler);
  },
};

registerPiSession(pi as never);

afterEach(async () => {
  await rm(registryFile, { force: true });
});

describe("pi session registry", () => {
  test("registers the current session ID on session_start", async () => {
    const handler = handlers.get("session_start");
    expect(handler).toBeDefined();

    await handler?.({}, {
      sessionManager: { getSessionId: () => "pi-session-id" },
    });

    expect(await readFile(registryFile, "utf8")).toBe("pi-session-id\n");
  });

  test("removes the registry file on session_shutdown", async () => {
    await handlers.get("session_start")?.({}, {
      sessionManager: { getSessionId: () => "pi-session-id" },
    });

    await handlers.get("session_shutdown")?.({}, {});

    expect(readFile(registryFile, "utf8")).rejects.toThrow();
  });
});
