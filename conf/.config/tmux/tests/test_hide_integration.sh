#!/usr/bin/env bash
# test_hide_integration.sh: hide-session.sh の hide_session() を独立tmuxソケットで検証する。
# switch-client はクライアントが必要なため対象外（target 出力までは検証する）。
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_assert.sh"

HIDE_SCRIPT="$SCRIPT_DIR/../scripts/hide-session.sh"
if [[ ! -f "$HIDE_SCRIPT" ]]; then
    assert_fail "hide-session.sh が存在しない（${HIDE_SCRIPT}）"
    report_assertions
    exit 1
fi

# 独立ソケットへ強制する tmux ラッパー（テストサーバーは本番に触れない）
WRAP=/tmp/tmux-wrap-hide
mkdir -p "$WRAP"
# 実 tmux の絶対パスを固定（ラッパー自身が PATH に入ると env tmux が自分を再帰するため）
REAL_TMUX="$(command -v tmux)"
cat > "$WRAP/tmux" <<EOF
#!/usr/bin/env bash
exec "$REAL_TMUX" -L hide-int-test "\$@"
EOF
chmod +x "$WRAP/tmux"
export PATH="$WRAP:$PATH"

# テストサーバーを起動し、作成順: floorCPM, dotfiles, sazabi を作る
# session_created の秒が揃うと macOS の sort -n で順序が不定になるため、間に sleep を挟む
tmux kill-server 2>/dev/null || true
sleep 0.2
tmux new-session -d -s floorCPM -c /tmp
sleep 1.1
tmux new-session -d -s dotfiles -c /tmp
sleep 1.1
tmux new-session -d -s sazabi -c /tmp
sleep 0.3
created="$(tmux list-sessions -F '#{session_created} #{session_name}' | sort -n | awk '{print $2}' | tr '\n' ' ')"
assert_eq "作成順が floorCPM dotfiles sazabi" "floorCPM dotfiles sazabi " "$created"

set +euo pipefail
source "$HIDE_SCRIPT"
set +euo pipefail

# --- 1. 中間セッションを隠す → 前の可視セッション（floorCPM）がターゲット ---
target=""
if target=$(hide_session "dotfiles"); then
    assert_eq "hide dotfiles -> target floorCPM" "floorCPM" "$target"
else
    assert_fail "hide_session dotfiles が失敗"
fi
hidden=$(tmux show-options -t dotfiles -v @hidden)
assert_eq "@hidden on が設定される" "on" "$hidden"
fmts=$(tmux show-options -g status-format | grep -c 'client_session},dotfiles}' || true)
assert_eq "縦リストから dotfiles が除外される" "0" "$fmts"

# --- 2. 残り可視 [floorCPM, sazabi] から sazabi を隠す → floorCPM ---
target=""
if target=$(hide_session "sazabi"); then
    assert_eq "hide sazabi -> target floorCPM" "floorCPM" "$target"
else
    assert_fail "hide_session sazabi が失敗"
fi

# --- 3. 最後の可視セッション（floorCPM）は隠せない（exit 1） ---
if hide_session "floorCPM" >/dev/null 2>&1; then
    assert_fail "最後の可視セッションを隠すべきでない"
else
    assert_pass "最後の可視セッションの隠下は拒否される"
fi

# --- 4. 既に隠したセッションを再度隠そうとすると exit 1 ---
if hide_session "dotfiles" >/dev/null 2>&1; then
    assert_fail "既に隠したセッションの再隠しは拒否されるべき"
else
    assert_pass "既に隠したセッションの再隠しは拒否される"
fi

tmux kill-server 2>/dev/null || true
report_assertions