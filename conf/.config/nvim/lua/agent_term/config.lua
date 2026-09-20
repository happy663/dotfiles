local M = {}

M.draft = {
  fallback_target_patterns = { "claude", "codex", "pi" },
  attached_height = 8,
  -- 送信前にターゲットターミナルへ送る入力クリアシーケンス。
  -- デフォルトは backspace (\x7f) を多めに送ることで、改行込みの複数行入力も
  -- TUI 実装に依存せず削除する。Ctrl+U (\x15) は readline multiline や一部 TUI で
  -- 現在行しかクリアできないためデフォルトでは使わない。
  clear_input_sequence = string.rep("\x7f", 5000),
}

M.claude = {
  draft_height = 8,
}

M.codex = {
  draft_height = 8,
}

M.pi = {
  draft_height = 8,
}

M.claude_codex = {
  draft_height = 8,
  open_in_new_tab = true,
}

M.claude_pair = {
  input_height = 15,
  padding_width = 15,
  fallback_target_patterns = { "claude" },
}

M.send_to = {
  -- ピッカーを開いている間、一覧を自動で取り直す間隔（ms）。
  -- 0 以下にすると自動更新しない（手動の AgentSendToRefresh のみ）。
  refresh_interval_ms = 5000,
  preview = {
    -- 左カラム（一覧 + 下書き） : プレビュー の比率。0.2 で 2:8。
    -- 左カラムが狭くなりすぎる場合は min_left_width が優先される。
    ratio = 0.2,
    -- 左カラムの最低幅（列）。狭い画面でプレビューを失わないための下限。
    min_left_width = 30,
    -- プレビューに出す履歴の行数（末尾から）。
    history_lines = 500,
    -- 折り返し。false は nowrap で、長い行は zh / zl で横にずらして見る。
    -- true にすると折り返し、breakindent と showbreak で継続行を区別する。
    wrap = false,
    -- 取得のタイムアウト（ms）。相手 nvim が応答しない場合の上限。
    fetch_timeout_ms = 800,
    -- 選択が変わってから取得するまでの待ち時間（ms）。連打しても最後の1回だけ走らせる。
    debounce_ms = 50,
    -- 失敗表示を出すまでの連続失敗回数。1回だけの失敗は前回の内容を保って無視する。
    failure_threshold = 2,
    -- プレビュー幅がこれ未満なら出さない。
    min_preview_width = 36,
    -- プレビュー（ピッカー全体）の高さを画面の何割使うか。
    -- 左カラムとは切り離しているので、一覧が短くてもプレビューはこの高さになる。
    height_ratio = 0.9,
    -- 下書き（Prompt）の高さ。プレビューの高さには影響しない。
    draft_height = 8,
  },
}

return M
