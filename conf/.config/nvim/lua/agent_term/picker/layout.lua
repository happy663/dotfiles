-- ピッカーの浮きウィンドウ配置を計算する純関数。
-- ウィンドウ操作を含まないので、テストから直接叩ける（tests/test_agent_term_preview_layout.lua）。
--
-- 2カラム（左: 一覧 + 下書き / 右: プレビュー）を基本とし、
-- プレビューを出すと左カラムが読めなくなる幅では既存の1カラムへフォールバックする。
local M = {}

-- 既定値。config.send_to.preview から上書きされる。
M.DEFAULTS = {
  -- 左カラム : プレビュー = 3 : 7
  ratio = 0.3,
  -- 左カラムとプレビューの間隔（列）
  gap = 2,
  -- 画面端からの余白（左右に半分ずつ使う）。浮きウィンドウの枠を描くのに要る。
  margin = 4,
  -- これ未満ならプレビューを出さない
  min_preview_width = 36,
  -- 左カラムがこれ未満になるならプレビューを出さない（下書きが書けなくなるため）
  min_left_width = 50,
  -- 1カラム時の幅。既存実装の値をそのまま踏襲する。
  max_width = 100,
  min_width = 40,
  -- 一覧の高さ上限。件数が増えてもプレビューを食い潰さない。
  list_max_height = 10,
  draft_height = 8,
}

local function opt(opts, key)
  local value = opts[key]
  if value == nil then
    return M.DEFAULTS[key]
  end
  return value
end

-- opts は { columns?, lines?, list_count? } に加え、テストから既定値を上書きできる。
-- 返る寸法はウィンドウの content 基準（枠は content の外側に1桁ずつ描かれる）。
function M.calculate(opts)
  opts = opts or {}
  local columns = opts.columns or vim.o.columns
  local lines = opts.lines or vim.o.lines
  local list_count = opts.list_count or 0

  local draft_height = opt(opts, "draft_height")
  local list_height = math.max(1, math.min(math.max(list_count, 1), opt(opts, "list_max_height")))
  local total_height = list_height + draft_height + 4
  local row = math.max(0, math.floor((lines - total_height) / 2))

  local gap = opt(opts, "gap")
  local total_width = columns - opt(opts, "margin")
  local left_width = math.floor(total_width * opt(opts, "ratio"))
  local preview_width = total_width - left_width - gap
  local preview_visible = preview_width >= opt(opts, "min_preview_width") and left_width >= opt(opts, "min_left_width")

  if not preview_visible then
    -- 既存の1カラム。狭い画面でプレビューを出すと、一覧も下書きも読めなくなるため。
    local width = math.min(opt(opts, "max_width"), math.max(opt(opts, "min_width"), columns - 8))
    return {
      columns = columns,
      preview_visible = false,
      total_width = width,
      left_width = width,
      gap = 0,
      preview_width = 0,
      list_height = list_height,
      draft_height = draft_height,
      preview_height = 0,
      preview_row = nil,
      preview_col = nil,
      row = row,
      draft_row = row + list_height + 2,
      col = math.max(0, math.floor((columns - width) / 2)),
    }
  end

  local col = math.max(0, math.floor((columns - total_width) / 2))
  return {
    columns = columns,
    preview_visible = true,
    total_width = total_width,
    left_width = left_width,
    gap = gap,
    preview_width = preview_width,
    list_height = list_height,
    draft_height = draft_height,
    -- 枠の外側を左カラムに揃える高さ。一覧の上枠（row - 1）から下書きの下枠
    -- （row + list_height + draft_height + 2）まで。プレビューは左カラム全体を覆う。
    preview_height = list_height + draft_height + 2,
    preview_row = row,
    preview_col = col + left_width + gap,
    row = row,
    draft_row = row + list_height + 2,
    col = col,
  }
end

return M
