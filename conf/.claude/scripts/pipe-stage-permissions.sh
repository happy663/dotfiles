#!/usr/bin/env bash
# PreToolUse hook: auto-approve piped commands when all stages are in allow list
# Workaround for Claude Code GitHub Issue #29967
# Reference: https://note.com/bitprogress/n/nf8316a56e493

INPUT=$(cat)

# Extract command
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -z "$COMMAND" ] && exit 0

SETTINGS_FILE="$HOME/.claude/settings.json"
[ ! -f "$SETTINGS_FILE" ] && exit 0

# Export command for Python subprocess
export CLAUDE_HOOK_COMMAND="$COMMAND"

python3 - << 'PYEOF'
import sys, json, os, re

settings_file = os.path.expanduser("~/.claude/settings.json")
try:
    with open(settings_file) as f:
        settings = json.load(f)
except Exception:
    sys.exit(0)

permissions = settings.get("permissions", {})
allow_list = permissions.get("allow", [])
deny_list = permissions.get("deny", [])

def get_bash_patterns(lst):
    patterns = []
    for item in lst:
        if isinstance(item, str) and item.startswith("Bash(") and item.endswith(")"):
            patterns.append(item[5:-1])
    return patterns

allow_patterns = get_bash_patterns(allow_list)
deny_patterns = get_bash_patterns(deny_list)

def matches(cmd, patterns):
    for pattern in patterns:
        if ":" in pattern:
            prefix, _, rest = pattern.partition(":")
            if rest == "*":
                if cmd == prefix or cmd.startswith(prefix + " "):
                    return True
        else:
            if cmd == pattern:
                return True
    return False

command = os.environ.get("CLAUDE_HOOK_COMMAND", "")
if not command:
    sys.exit(0)

# Security: block dangerous env var injections
if re.search(r'(?:^|[\s;|&])(PATH=|LD_PRELOAD=|LD_LIBRARY_PATH=|DYLD_)', command):
    sys.exit(0)

def split_stages(cmd):
    """Split command by | && ; while respecting quotes and backslash escapes."""
    stages = []
    stage = ""
    in_sq = False
    in_dq = False
    i = 0
    while i < len(cmd):
        c = cmd[i]
        # Backslash escape handling
        if c == '\\' and not in_sq:
            if in_dq:
                # In double quotes: \ only escapes " \ $ ` and newline
                if i + 1 < len(cmd) and cmd[i+1] in ('"', '\\', '$', '`', '\n'):
                    stage += c + cmd[i+1]
                    i += 2
                    continue
                else:
                    stage += c
            else:
                # Outside quotes: \ escapes next char (prevents pipe splitting)
                if i + 1 < len(cmd):
                    stage += c + cmd[i+1]
                    i += 2
                    continue
                else:
                    stage += c
        elif c == "'" and not in_dq:
            in_sq = not in_sq
            stage += c
        elif c == '"' and not in_sq:
            in_dq = not in_dq
            stage += c
        elif not in_sq and not in_dq:
            if c == '|' and i + 1 < len(cmd) and cmd[i+1] == '|':
                stages.append(stage.strip())
                stage = ""
                i += 2
                continue
            elif c == '|':
                stages.append(stage.strip())
                stage = ""
            elif c == '&' and i + 1 < len(cmd) and cmd[i+1] == '&':
                stages.append(stage.strip())
                stage = ""
                i += 2
                continue
            elif c == ';':
                stages.append(stage.strip())
                stage = ""
            else:
                stage += c
        else:
            stage += c
        i += 1
    if stage.strip():
        stages.append(stage.strip())
    return [s for s in stages if s]

stages = split_stages(command)
if not stages:
    sys.exit(0)

for stage in stages:
    if matches(stage, deny_patterns):
        sys.exit(0)
    if not matches(stage, allow_patterns):
        sys.exit(0)

print('{"decision": "approve"}')
PYEOF
