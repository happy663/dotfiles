# Safari GitHub Image Upload Tool

neovimからGitHub issueに画像を直接アップロードするためのツール

## 🚀 機能

- **neovimから直接画像アップロード**: クリップボードの画像をGitHub issueに6秒程度でアップロード
- **永続ログインセッション**: 一度ログインすれば次回から自動認証
- **プライベート環境**: 外部サービス不使用、完全にローカルで動作
- **二段階認証対応**: 手動ログインで確実に認証突破

## 📋 前提条件

- **macOS**: Safari自動化機能が必要
- **Python 3**: Playwrightライブラリが必要
- **Safari**: リモート自動化設定が必要
- **GitHub アカウント**: 対象リポジトリへのアクセス権限

## 🛠️ セットアップ

### 1. 依存関係のインストール

```bash
# Python依存関係
pip3 install playwright

# Playwrightブラウザ
playwright install webkit

# 画像処理ツール
brew install pngpaste
```

### 2. Safari設定

1. Safari > 設定 > 詳細 > 「開発メニューを表示」をチェック
2. 開発 > リモート自動化を許可 をチェック

### 3. 初回セットアップ

```bash
python3 safari_persistent_upload.py --setup
```

## 📖 使用方法

### neovimから使用

```vim
:GitHubImageUpload
" または
<leader>gi
```

### コマンドラインから使用

```bash
# クリップボードから
python3 safari_persistent_upload.py https://github.com/owner/repo/issues/123

# ファイルから
python3 safari_persistent_upload.py https://github.com/owner/repo/issues/123 --image /path/to/image.png
```

## 🔧 トラブルシューティング

### よくある問題

1. **権限エラー**: システム設定でターミナル/Pythonに自動化権限を許可
2. **ログインエラー**: `--setup`で再ログイン
3. **アップロード失敗**: リポジトリへのアクセス権限を確認

### 環境確認

```bash
./quick_test.sh
```
