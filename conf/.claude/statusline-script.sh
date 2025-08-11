#!/bin/bash

# Claude Code ステータスライン
# フォーマット: dir | branch | model | costs (色付き)
# echo '{"session_id": "...", "model": {...}}' | bash ~/.claude/statusline-script.sh

# カラーコード定義
BLUE='\033[34m'      # モデル名用
CYAN='\033[36m'      # ディレクトリ名用
GREEN='\033[32m'     # Gitブランチ用
YELLOW='\033[33m'    # 料金情報用
GRAY='\033[90m'      # 区切り文字用
RESET='\033[0m'      # リセット

# JSONデータを取得
input=$(cat)
model_name=$(echo "$input" | jq -r '.model.display_name')
current_dir=$(echo "$input" | jq -r '.workspace.current_dir')

# 現在のディレクトリ名のみ取得
dir_name=$(basename "$current_dir")

# Gitブランチ取得（現在のディレクトリで実行）
git_branch=""
if [ -d "$current_dir" ]; then
    git_branch=$(cd "$current_dir" 2>/dev/null && git branch --show-current 2>/dev/null || echo "")
fi

# ccusage情報取得（必要なフィールドがある場合のみ）
ccusage_info=""
if command -v npx >/dev/null 2>&1; then
    # 必要なフィールドが存在するかチェック
    session_id=$(echo "$input" | jq -r '.session_id // empty')
    transcript_path=$(echo "$input" | jq -r '.transcript_path // empty')
    cwd=$(echo "$input" | jq -r '.cwd // empty')
    model_id=$(echo "$input" | jq -r '.model.id // empty')
    project_dir=$(echo "$input" | jq -r '.workspace.project_dir // empty')
    
    # すべての必須フィールドが存在する場合のみccusageを実行
    if [ -n "$session_id" ] && [ -n "$transcript_path" ] && [ -n "$cwd" ] && [ -n "$model_id" ] && [ -n "$project_dir" ]; then
        # ローカルの修正版ccusageを使用
        full_ccusage=$(echo "$input" | node $(ghq root)/github.com/ryoppippi/ccusage/dist/index.js statusline 2>/dev/null || echo "")
        # sessionとtodayの料金だけを抽出
        if [ -n "$full_ccusage" ]; then
            # $記号を含む数値を抽出（例: "N/A session / $16.03 today" から "$16.03" を取得）
            session_cost=$(echo "$full_ccusage" | grep -oE '\$[0-9]+\.[0-9]+ session' | grep -oE '\$[0-9]+\.[0-9]+' || echo "")
            today_cost=$(echo "$full_ccusage" | grep -oE '\$[0-9]+\.[0-9]+ today' | grep -oE '\$[0-9]+\.[0-9]+' || echo "")
            
            # N/A sessionの場合の処理とコスト表示の構築
            if echo "$full_ccusage" | grep -q "N/A session"; then
                # セッションがN/Aの場合は今日の料金のみ表示
                if [ -n "$today_cost" ]; then
                    ccusage_info="${today_cost}/day"
                fi
            else
                # セッション料金がある場合
                if [ -n "$session_cost" ] && [ -n "$today_cost" ]; then
                    ccusage_info="${session_cost}/${today_cost}"
                elif [ -n "$session_cost" ]; then
                    ccusage_info="${session_cost}"
                elif [ -n "$today_cost" ]; then
                    ccusage_info="${today_cost}/day"
                fi
            fi
        fi
    fi
fi

# 出力を構築（色付き、区切り文字は " | "）
# 順序: dir | branch | model | costs
output="${CYAN}${dir_name}${RESET}"

if [ -n "$git_branch" ]; then
    output="$output${GRAY}:${RESET}${GREEN}${git_branch}${RESET}"
fi

output="$output ${GRAY}|${RESET} ${BLUE}${model_name}${RESET}"

if [ -n "$ccusage_info" ]; then
    output="$output ${GRAY}|${RESET} ${YELLOW}${ccusage_info}${RESET}"
fi

# echo -e で色を有効化
echo -e "$output"
