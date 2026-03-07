#!/usr/bin/env python3
import json
import os
import subprocess
import sys
from datetime import datetime
from shutil import which


def _truncate(text: str, max_len: int = 140) -> str:
    if len(text) <= max_len:
        return text
    return text[: max_len - 1] + "..."


def _debug_log(message: str) -> None:
    # Keep lightweight diagnostics to verify whether Codex invoked this hook.
    log_path = os.path.expanduser("~/.codex/log/notify-hook.log")
    try:
        os.makedirs(os.path.dirname(log_path), exist_ok=True)
        with open(log_path, "a", encoding="utf-8") as f:
            f.write(f"{datetime.now().isoformat()} {message}\n")
    except Exception:
        pass


def _first_input_message(payload: dict) -> str | None:
    messages = payload.get("input-messages")
    if messages is None:
        messages = payload.get("input_messages")
    if not isinstance(messages, list) or not messages:
        return None

    first = messages[0]
    if isinstance(first, str):
        return first
    if isinstance(first, dict):
        content = first.get("content")
        if isinstance(content, str):
            return content
    return None


def _pick_notifier() -> str | None:
    candidates = [
        which("terminal-notifier"),
        "/Users/happy/.nix-profile/bin/terminal-notifier",
        "/opt/homebrew/bin/terminal-notifier",
        "/usr/local/bin/terminal-notifier",
    ]
    for candidate in candidates:
        if candidate and os.path.isfile(candidate) and os.access(candidate, os.X_OK):
            return candidate
    return None


def main() -> int:
    if len(sys.argv) < 2:
        return 0

    try:
        payload = json.loads(sys.argv[1])
    except json.JSONDecodeError:
        _debug_log("invalid-json-payload")
        return 0

    event = payload.get("type") or payload.get("event") or "notification"
    title = "Codex"

    if event == "agent-turn-complete":
        turn = payload.get("turn", {}) if isinstance(payload.get("turn"), dict) else {}
        input_message = _first_input_message(payload)
        title = "Codex: Turn Complete"
        message = (
            turn.get("summary")
            or payload.get("last-assistant-message")
            or input_message
            or "作業が完了しました"
        )
    elif event == "approval-requested":
        title = "Codex: Approval Requested"
        reason = payload.get("reason")
        message = f"承認が必要です: {reason}" if reason else "承認が必要です"
    else:
        message = payload.get("message") or f"event: {event}"
    message = _truncate(str(message))

    notifier = _pick_notifier()
    _debug_log(f"event={event} notifier={notifier}")
    if notifier:
        result = subprocess.run(
            [notifier, "-title", title, "-message", message],
            check=False,
        )
        _debug_log(f"terminal-notifier-returncode={result.returncode}")
        if result.returncode == 0:
            return 0

    _debug_log("fallback=bel")
    sys.stdout.write("\a")
    sys.stdout.flush()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
