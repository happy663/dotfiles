# 自動更新 PR の Neovim 解説

`update.yaml` は Neovim の旧・新 rev の `runtime/doc/news.txt` とコミット一覧を収集し、
行番号付きの `conf/.config/nvim` とともに Pi に渡します。
Pi 1.4.0 / OpenCode Go / `deepseek-v4.1-flash` を使用します。
解説 → news.txt 差分 → fix → vim-patch（折りたたみ）→ その他のコミット → compare の順に載せます。

## 初回設定

1. OpenCode Console の個人 workspace で Go を契約し、個人 API キーを作成する。
2. リポジトリの Actions secret `OPENCODE_API_KEY` に登録する。
3. Console の Settings → Privacy → Regions で **Global** を許可する（DeepSeek に必要）。
4. Go の **Extra Usage** は無効にする。上限到達時はAI解説なしで更新 PR を作る。
5. マージ後に Update workflow を手動実行し、接続・解説・利用量を確認する。

キーを再発行した場合は同じ secret を更新します。キーの値を Issue やログに貼らないでください。

## 失敗・サイズ制限

- Secret 未設定、npm / API の障害、利用枠到達、タイムアウト時も更新 PR は作成する。
- AI の処理は5分、推論プロセスは180秒まで。失敗時は一時出力を採用しない。
- news.txt の追加行は300行まで。超過時は差分の代わりに compare を案内する。
- 大規模な削除はリセットの可能性として表示する。追加行なしを「変更なし」とは判断しない。
- 資料は約22000文字、AI解説は12000文字まで。超過するAI解説は採用しない。
- 設定入力は1000000文字まで。超過時はAIを実行せず、収集した資料だけを掲載する。
- Nix更新ログは15000文字まで。PR本文はファイルで渡し、multiline output の区切り文字衝突を避ける。

AI はツール・拡張・MCP・スキル・会話保存・リポジトリ内の指示の読み込みを無効にして実行する。
設定はスクリプトで入力に含めるため、モデルにシェル実行やファイル書き込みを許可しない。
ただし、資料中の文章によって解説が誘導されたり誤った解説が出たりする可能性はある。
必ず併記した資料と照合して判断する。

DeepSeek の地域・保持条件やモデル提供状況は変更されるため、Go の公式資料も確認する。

- [Go / Pi 接続](https://github.com/anomalyco/opencode/blob/dev/services/www/src/docs/content/console/harnesses/pi.mdx)
- [Go の制限・Privacy](https://github.com/anomalyco/opencode/blob/dev/services/www/src/docs/content/console/go.mdx)
- [Pi CLI](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/cli.md)
