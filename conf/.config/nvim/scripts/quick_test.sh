#!/bin/bash

# Safari GitHub画像アップロード機能 クイックテスト

echo "🧪 Safari GitHub画像アップロード機能 クイックテスト"
echo "================================================"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PERSISTENT_SCRIPT="$SCRIPT_DIR/safari_persistent_upload.py"

# スクリプトの存在確認
if [ ! -f "$PERSISTENT_SCRIPT" ]; then
    echo "❌ スクリプトが見つかりません: $PERSISTENT_SCRIPT"
    exit 1
fi

echo "✅ スクリプトファイル確認済み"

# uvとplaywrightの確認
echo "🔍 Python環境を確認中..."

if ! command -v uv &> /dev/null; then
    echo "❌ uv が見つかりません"
    echo "   インストール: Nix（home-manager/common.nix）で導入"
    exit 1
fi

echo "✅ uv 確認済み"

# Playwrightの確認（Neovimと同じく uv run --script で依存を解決して import できるか）
if ! uv run --script "$PERSISTENT_SCRIPT" --help &> /dev/null; then
    echo "❌ Playwright を読み込めません"
    echo "   確認: uv run --script $PERSISTENT_SCRIPT --help"
    exit 1
fi

echo "✅ Playwright 確認済み"

# pngpasteの確認
if ! command -v pngpaste &> /dev/null; then
    if [ -f "/opt/homebrew/opt/pngpaste/bin/pngpaste" ]; then
        echo "✅ pngpaste 確認済み"
    else
        echo "❌ pngpaste が見つかりません"
        echo "   インストール: brew install pngpaste"
        exit 1
    fi
else
    echo "✅ pngpaste 確認済み"
fi

# セッションディレクトリの確認
SESSION_DIR="$HOME/.config/nvim/safari-github-profile"
if [ -d "$SESSION_DIR" ]; then
    echo "✅ セッションディレクトリ確認済み: $SESSION_DIR"
    echo "   (ログインセッションが保存されている可能性があります)"
else
    echo "⚠️  セッションディレクトリがありません: $SESSION_DIR"
    echo "   初回セットアップが必要です"
fi

echo ""
echo "🎯 次のステップ:"
echo ""

if [ ! -d "$SESSION_DIR" ]; then
    echo "1. 初回セットアップを実行:"
    echo "   uv run --script $PERSISTENT_SCRIPT --setup"
    echo ""
fi

echo "2. テスト画像をクリップボードにコピー"
echo ""
echo "3. 画像アップロードをテスト:"
echo "   uv run --script $PERSISTENT_SCRIPT https://github.com/owner/repo/issues/123"
echo ""
echo "4. neovimでの使用:"
echo "   :GitHubImageUpload または <leader>gi"
echo ""

echo "📖 詳細な使用方法:"
echo "   cat $SCRIPT_DIR/USAGE_GUIDE.md"

echo ""
echo "🎉 環境確認完了！"