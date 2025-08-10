#!/bin/bash


# Claude Code シンプルステータスライン
# フォーマット: model/dir/branch/ccusage_info
# echo '{"session_id": "...", "model": {...}}' | bash ~/.claude/statusline-script.sh

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
        full_ccusage=$(echo "$input" | npx ccusage statusline 2>/dev/null || echo "")
        # sessionとtodayの料金だけを抽出
        if [ -n "$full_ccusage" ]; then
            # $記号を含む数値を抽出（例: "N/A session / $16.03 today" から "$16.03" を取得）
            session_cost=$(echo "$full_ccusage" | grep -oE '\$[0-9]+\.[0-9]+ session' | grep -oE '\$[0-9]+\.[0-9]+' || echo "")
            today_cost=$(echo "$full_ccusage" | grep -oE '\$[0-9]+\.[0-9]+ today' | grep -oE '\$[0-9]+\.[0-9]+' || echo "")
            
            # N/A sessionの場合の処理
            if echo "$full_ccusage" | grep -q "N/A session"; then
                session_cost="N/A"
            fi
            
            # 短縮形式で出力
            if [ -n "$session_cost" ] && [ -n "$today_cost" ]; then
                ccusage_info="${session_cost}/${today_cost}"
            elif [ -n "$today_cost" ]; then
                ccusage_info="${today_cost}"
            fi
        fi
    fi
fi

# 出力を構築
output="$model_name/$dir_name"

if [ -n "$git_branch" ]; then
    output="$output/$git_branch"

fi

if [ -n "$ccusage_info" ]; then
    output="$output/$ccusage_info"
fi

echo "$output"
