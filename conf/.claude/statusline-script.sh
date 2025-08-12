#!/bin/bash

# Claude Code ステータスライン
# フォーマット: dir | branch | model | tokens | costs (色付き)
# echo '{"session_id": "...", "model": {...}}' | bash ~/.claude/statusline-script.sh

# カラーコード定義
BLUE='\033[34m'      # モデル名用
CYAN='\033[36m'      # ディレクトリ名用
GREEN='\033[32m'     # Gitブランチ用
YELLOW='\033[33m'    # 料金情報用
GRAY='\033[90m'      # 区切り文字用
RED='\033[31m'       # 高使用率警告用
RESET='\033[0m'      # リセット

# 定数
COMPACTION_THRESHOLD=160000  # 200000 * 0.8

# JSONデータを取得
input=$(cat)
model_name=$(echo "$input" | jq -r '.model.display_name')
current_dir=$(echo "$input" | jq -r '.workspace.current_dir')
session_id=$(echo "$input" | jq -r '.session_id // empty')

# 現在のディレクトリ名のみ取得
dir_name=$(basename "$current_dir")

# Gitブランチ取得（現在のディレクトリで実行）
git_branch=""
if [ -d "$current_dir" ]; then
    git_branch=$(cd "$current_dir" 2>/dev/null && git branch --show-current 2>/dev/null || echo "")
fi

# トークン計算関数
calculate_tokens() {
    local session_id="$1"
    local projects_dir="$HOME/.claude/projects"
    
    if [ -z "$session_id" ] || [ ! -d "$projects_dir" ]; then
        echo "0|0"
        return
    fi
    
    # セッションファイルを検索
    local transcript_file=""
    for project_dir in "$projects_dir"/*; do
        if [ -d "$project_dir" ]; then
            local file="$project_dir/${session_id}.jsonl"
            if [ -f "$file" ]; then
                transcript_file="$file"
                break
            fi
        fi
    done
    
    if [ -z "$transcript_file" ] || [ ! -f "$transcript_file" ]; then
        echo "0|0"
        return
    fi
    
    # 最後のassistantメッセージのusageを取得
    local total_tokens=0
    local last_usage=$(tac "$transcript_file" 2>/dev/null | while IFS= read -r line; do
        # JSONとして解析を試みる
        if echo "$line" | jq -e '.type == "assistant" and .message.usage' >/dev/null 2>&1; then
            echo "$line" | jq -r '.message.usage | @json'
            break
        fi
    done)
    
    if [ -n "$last_usage" ]; then
        # トークン数を計算
        local input_tokens=$(echo "$last_usage" | jq -r '.input_tokens // 0')
        local output_tokens=$(echo "$last_usage" | jq -r '.output_tokens // 0')
        local cache_creation=$(echo "$last_usage" | jq -r '.cache_creation_input_tokens // 0')
        local cache_read=$(echo "$last_usage" | jq -r '.cache_read_input_tokens // 0')
        
        total_tokens=$((input_tokens + output_tokens + cache_creation + cache_read))
    fi
    
    # トークン数をフォーマット
    local token_display=""
    if [ "$total_tokens" -ge 1000000 ]; then
        token_display=$(awk "BEGIN {printf \"%.1fM\", $total_tokens/1000000}")
    elif [ "$total_tokens" -ge 1000 ]; then
        token_display=$(awk "BEGIN {printf \"%.1fK\", $total_tokens/1000}")
    else
        token_display="$total_tokens"
    fi
    
    # パーセンテージを計算
    local percentage=$(awk "BEGIN {p = int(($total_tokens / $COMPACTION_THRESHOLD) * 100); print (p > 100) ? 100 : p}")
    
    echo "${token_display}|${percentage}"
}

# トークン使用量情報取得
token_info=""
if [ -n "$session_id" ]; then
    token_result=$(calculate_tokens "$session_id")
    if [ -n "$token_result" ]; then
        # フォーマット: tokens|percentage
        token_display=$(echo "$token_result" | cut -d'|' -f1)
        percentage=$(echo "$token_result" | cut -d'|' -f2)
        
        if [ -n "$token_display" ] && [ -n "$percentage" ]; then
            # 使用率に応じて色を設定
            if [ "$percentage" -ge 90 ]; then
                token_color="$RED"
            elif [ "$percentage" -ge 70 ]; then
                token_color="$YELLOW"
            else
                token_color="$GREEN"
            fi
            
            # 0でも表示する（初期表示）
            if [ "$token_display" = "0" ]; then
                token_info="${GRAY}0 tokens (0%)${RESET}"
            else
                token_info="${token_display} (${token_color}${percentage}%${RESET})"
            fi
        fi
    fi
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
        full_ccusage=$(echo "$input" | npx ccusage statusline 2>/dev/null || echo "")
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
# 順序: dir | branch | model | tokens | costs
output="${CYAN}${dir_name}${RESET}"

if [ -n "$git_branch" ]; then
    output="$output${GRAY}:${RESET}${GREEN}${git_branch}${RESET}"
fi

output="$output ${GRAY}|${RESET} ${BLUE}${model_name}${RESET}"

if [ -n "$token_info" ]; then
    output="$output ${GRAY}|${RESET} ${token_info}"
fi

if [ -n "$ccusage_info" ]; then
    output="$output ${GRAY}|${RESET} ${YELLOW}${ccusage_info}${RESET}"
fi

# echo -e で色を有効化
echo -e "$output"
