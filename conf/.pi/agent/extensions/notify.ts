import { execFile } from "node:child_process";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

function notify(title: string, body: string): void {
  if (process.platform === "darwin") {
    execFile("terminal-notifier", [
      "-title",
      title,
      "-message",
      body,
      "-group",
      "pi-agent",
    ]);
  } else if (process.env.KITTY_WINDOW_ID) {
    // Kitty: OSC 99
    process.stdout.write(`\x1b]99;i=pi:d=0;${title}\x1b\\`);
    process.stdout.write(`\x1b]99;i=pi:p=body;${body}\x1b\\`);
  } else {
    // Ghostty, iTerm2, WezTerm: OSC 777
    process.stdout.write(`\x1b]777;notify;${title};${body}\x07`);
  }
}

export default function (pi: ExtensionAPI) {
  pi.on("agent_settled", async () => {
    notify("Pi", "Ready for input");
  });
}
