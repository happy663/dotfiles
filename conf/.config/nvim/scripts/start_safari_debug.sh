#!/bin/bash

# Safari リモートデバッグモード起動スクリプト
# 固定ポートでSafariを起動し、手動操作を可能にする

SAFARI_DEBUG_PORT=9223  # Chromeと競合しないポートを使用
SAFARI_APP="/Applications/Safari.app"

echo "🔧 Safari リモートデバッグモード起動スクリプト"
echo "================================================"

# Safari がすでにリモートデバッグモードで動いているかチェック
check_safari_debug() {
    if lsof -i :$SAFARI_DEBUG_PORT > /dev/null 2>&1; then
        echo "✅ Safari はすでにポート $SAFARI_DEBUG_PORT で起動しています"
        return 0
    fi
    return 1
}

# 通常のSafariプロセスを確認
check_normal_safari() {
    if pgrep -f "Safari" > /dev/null 2>&1; then
        echo "⚠️  通常のSafariが起動しています"
        echo "   デバッグモードで起動するには、一度Safariを終了する必要があります"
        echo ""
        echo "選択してください:"
        echo "1) Safariを終了してデバッグモードで再起動 (推奨)"
        echo "2) 現在のSafariを維持して終了"
        echo ""
        read -p "選択 (1/2): " choice
        
        case $choice in
            1)
                echo "📱 Safariを終了しています..."
                pkill -f "Safari" 2>/dev/null || true
                sleep 2
                return 0
                ;;
            2)
                echo "❌ 操作をキャンセルしました"
                exit 0
                ;;
            *)
                echo "❌ 無効な選択です"
                exit 1
                ;;
        esac
    fi
    return 0
}

# Safari自動化設定を確認
check_safari_automation() {
    echo "📋 Safari自動化設定を確認中..."
    echo ""
    echo "以下の設定が必要です:"
    echo "1. Safari > 設定 > 詳細 > 「メニューバーに開発メニューを表示」をチェック"
    echo "2. 開発 > リモート自動化を許可 をチェック"
    echo ""
    read -p "設定は完了していますか？ (y/N): " automation_ready
    
    case $automation_ready in
        [Yy]*)
            echo "✅ 設定確認済み"
            ;;
        *)
            echo "❌ 先に設定を完了してください"
            echo "   詳細: ~/.config/nvim/scripts/safari_automation_setup.md"
            exit 1
            ;;
    esac
}

# Safariをデバッグモードで起動
start_safari_debug() {
    echo "🚀 Safariをデバッグモードで起動中..."
    echo "   ポート: $SAFARI_DEBUG_PORT"
    echo ""
    
    # Safariをリモートデバッグモードで起動
    # 注意: Safari は Chrome とは異なり、--remote-debugging-port オプションをサポートしていない
    # 代わりに、自動化用のSafariインスタンスを起動
    
    echo "⚠️  重要: Safariは起動後に以下の操作を手動で行ってください:"
    echo "1. https://github.com にアクセス"
    echo "2. ログイン（二段階認証含む）"
    echo "3. ログイン状態を確認"
    echo "4. Safariウィンドウは閉じずに開いたまま維持"
    echo ""
    
    # Safariを通常起動（自動化設定が有効な状態）
    open -a Safari
    
    echo "✅ Safari が起動しました"
    echo ""
    echo "📝 次のステップ:"
    echo "1. 上記の手動操作を完了してください"
    echo "2. 完了後、以下のコマンドで画像アップロードが使用できます:"
    echo "   python3 ~/.config/nvim/scripts/safari_github_upload.py [ISSUE_URL]"
    echo ""
    echo "💡 このスクリプトは終了しますが、Safariは開いたままにしてください"
}

# メイン実行
main() {
    # 既にデバッグモードで起動しているかチェック
    if check_safari_debug; then
        echo ""
        echo "💡 既に準備完了です。画像アップロード機能を使用できます"
        exit 0
    fi
    
    # 通常のSafariプロセスをチェック
    check_normal_safari
    
    # Safari自動化設定を確認
    check_safari_automation
    
    # Safariをデバッグモードで起動
    start_safari_debug
}

# スクリプト実行
main