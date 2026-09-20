-- ピッカーの浮きウィンドウ配置を計算する純関数。
-- ウィンドウ操作を含まないので、テストから直接叩ける（tests/test_agent_term_preview_layout.lua）。
--
-- 2カラム（左: 一覧 + 下書き / 右: プレビュー）を基本とし、
-- プレビューを出すと左カラムが読めなくなる幅では既存の1カラムへフォールバックする。
--
-- プレビューの高さは左カラムではなく画面高さ（height_ratio）から決める。
-- 左カラムに合わせると、一覧が短いときにプレビューまで短くなって読めないため。
local M = {}

-- 既定値。config.send_to.preview から上書きされる。
M.DEFAULTS = {
  -- 左カラム : プレビュー = 2 : 8
  ratio = 0.2,
  -- 左カラムとプレビューの間隔（列）
  gap = 2,
  -- 画面端からの余白（左右に半分ずつ使う）。浮きウィンドウの枠を描くのに要る。
  margin = 4,
  -- これ未満ならプレビューを出さない
  min_preview_width = 36,
  -- 左カラムの最低幅。比率で計算した値がこれを下回るなら、こちらを優先する
  -- （狭い画面でプレビューを失わないため）。
  min_left_width = 30,
  -- 1カラム時の幅。既存実装の値をそのまま踏襲する。
  max_width = 100,
  min_width = 40,
  -- 一覧の高さ上限。件数が増えてもプレビューを食い潰さない。
  list_max_height = 10,
  draft_height = 8,
  -- ピッカー（プレビュー）の高さを画面の何割使うか。
  -- プレビューは左カラムと切り離してこの高さになるので、agent の出力を広く読める。
  height_ratio = 0.9,
  -- 画面が低いときの最低高さ（行）。
  min_height = 12,
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
  local left_height = list_height + draft_height + 4
  -- プレビューを含むときの高さ。画面の height_ratio を使い、最低 min_height は確保する。
  local picker_height =
    math.max(1, math.min(lines - 2, math.max(opt(opts, "min_height"), math.floor(lines * opt(opts, "height_ratio")))))

  local gap = opt(opts, "gap")
  local total_width = columns - opt(opts, "margin")
  -- 比率で決めた幅が最低幅を下回るなら最低幅を優先する（プレビューを残すため）。
  local left_width = math.max(opt(opts, "min_left_width"), math.floor(total_width * opt(opts, "ratio")))
  local preview_width = total_width - left_width - gap
  local preview_visible = preview_width >= opt(opts, "min_preview_width")

  if not preview_visible then
    -- 既存の1カラム。狭い画面でプレビューを出すと、一覧も下書きも読めなくなるため。
    -- プレビューが無いので高さは内容なり（左カラム全体）で中央寄せする。
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
      left_height = left_height,
      picker_height = left_height,
      preview_height = 0,
      preview_row = nil,
      preview_col = nil,
      row = math.max(0, math.floor((lines - left_height) / 2)),
      draft_row = math.max(0, math.floor((lines - left_height) / 2)) + list_height + 2,
      col = math.max(0, math.floor((columns - width) / 2)),
    }
  end

  local row = math.max(0, math.floor((lines - picker_height) / 2))
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
    left_height = left_height,
    picker_height = picker_height,
    -- 枠の外側が picker_height 行に収まる高さ。プレビューは左カラムより縦に長い。
    preview_height = picker_height - 2,
    preview_row = row,
    preview_col = col + left_width + gap,
    row = row,
    draft_row = row + list_height + 2,
    col = col,
  }
end

return M
