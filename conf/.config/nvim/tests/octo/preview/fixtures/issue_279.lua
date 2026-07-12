-- Fixture: octo issue #279 の実バッファデータ
-- 2026-07-12 に conf:debug-nvim-tmux でサンプリング
-- コメント作成前の静止状態

return {
  bufname = "octo://happy663/dotfiles/issue/ターミナル内でのビューを快適にする方法を摸索する",
  filetype = "octo",
  line_count = 197,
  octo_buffer = {
    node = {
      number = 279,
      title = "ターミナル内でのビューを快適にする方法を摸索する",
    },
    titleMetadata = { startLine = 0, endLine = 0 },
    bodyMetadata = { startLine = 14, endLine = 21 },
    commentsMetadata = {
      { startLine = 27, endLine = 33, id = "IC_kwDOLSNlU88AAAABHJhAMA" },
      { startLine = 37, endLine = 39, id = "IC_kwDOLSNlU88AAAABHTvupQ" },
      { startLine = 43, endLine = 44, id = "IC_kwDOLSNlU88AAAABULyNg" },
      { startLine = 48, endLine = 54, id = "IC_kwDOLSNlU88AAAABIzpPmg" },
      { startLine = 58, endLine = 195, id = "IC_kwDOLSNlU88AAAABJu33FA" },
    },
  },
  -- buffer lines (1-indexed で提示、実際は 0-indexed で渡す想定)
  lines = {
    [1] = "ターミナル内でのビューを快適にする方法を摸索する",
    [15] = "ターミナルやNeovimの設定を調整して、人間が見た時の負荷を下げたい",
    [16] = " 調整できそうな所",
    [17] = "",
    [18] = "* font",
    [19] = "* 行間",
    [20] = "* rendar-markdownの色の見出しの色が目立って逆に文字を読みづらいかも",
    [21] = "* htmlみたいに文字のサイズを大きくしたりして見やすくできないのだろうか",
    [22] = "* mermaid記法をneovimでいい感じにビューできるようにしたい",
    [28] = "以下を導入した",
    [29] = "",
    [30] = "https://lineto.com/typefaces/akkurat-mono",
    [31] = "",
    [32] = "こんな感じの表示になる",
    [33] = "",
    [34] = '<img width="2386" height="1416" alt="Image" src="https://github.com/user-attachments/assets/68c802ac-72aa-4868-8a3a-673d208b860d" />',
    [38] = "rendar-markdownでmarkdownの読み書きをしてるけど",
    [39] = "読むのと書くのでは画面やバッファを分ける方がやっぱりいい気がするじ",
    [40] = "現状は読み書きが1つになっている",
    [44] = "cmuxでビューする所を作成するのもありなのかもしれない",
    [45] = "* https://zenn.dev/d0ne1s/articles/7adbd3a3d54b1d",
    [49] = "初見の大量の情報が書かれている文章を吸収する時にneovimで読もうとすると体感だけど結構頭に入ってこないケースがある",
    [50] = "Webでレンダリングされたものを見た方が頭に入ってきやすいなの気持ちになっている",
    [59] = "## 問題を octo.nvim ベースに絞り直した",
    [61] = "これまでの議論は「ターミナル / Neovim 全般の読みづらさ」だったが、実運用で一番よく使うのは octo.nvim で issue/PR を読む場面。そこが本当のペインポイントだった。",
  },
}
