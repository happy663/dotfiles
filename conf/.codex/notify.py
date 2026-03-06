#!/usr/bin/env python3
import json
import subprocess
import sys
from shutil import which


def main() -> int:
    if len(sys.argv) < 2:
        return 0

    try:
        payload = json.loads(sys.argv[1])
    except json.JSONDecodeError:
        return 0

    event = payload.get("event", "notification")
    title = "Codex"

    if event == "agent-turn-complete":
        turn = payload.get("turn", {})
        title = "Codex: Turn Complete"
        message = turn.get("summary") or "作業が完了しました"
    elif event == "approval-requested":
        title = "Codex: Approval Requested"
        reason = payload.get("reason")
        message = f"承認が必要です: {reason}" if reason else "承認が必要です"
    else:
        message = payload.get("message") or f"event: {event}"

    notifier = which("terminal-notifier")
    if notifier:
        subprocess.run(
            [notifier, "-title", title, "-message", message, "-sound", "Blow"],
            check=False,
        )
        return 0

    sys.stdout.write("\a")
    sys.stdout.flush()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
