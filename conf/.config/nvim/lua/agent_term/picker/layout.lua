-- ピッカーの浮きウィンドウ配置を計算する純関数。
-- ウィンドウ操作を含まないので、テストから直接叩ける（tests/test_agent_term_preview_layout.lua）。
--
-- 基本（横並び）:
--   ┌──────────────────────────┐
--   │        preview           │  上段: 全幅
--   ├───────────┬──────────────┤
--   │  prompt   │    agent     │  下段: 左に下書き、右に一覧
--   └───────────┴──────────────┘
--
-- 横並びの一覧が最低幅を割るとき（画面が狭い）は、プレビューを諦めて prompt と
-- agent を縦に積む（縦積み）。
-- 画面が低いときはプレビューを出さず、下段の横並びだけを出す。
--
-- ピッカー全体の幅は画面の width_ratio（既定 0.8）、高さは画面の height_ratio
-- （既定 1.0 = 罫線込みで収まる上限まで）を使う。
-- 下段の高さは 下書き(draft_height) と 一覧の件数 の大きい方に揃える（罫線を合わせるため）。
local M = {}

-- 既定値。config.send_to.preview から上書きされる。
M.DEFAULTS = {
  -- ピッカー全体の幅を画面の何割使うか。0.8 で 8 割。
  width_ratio = 0.8,
  -- 下段 prompt : agent の prompt の取り分。0.3 で 3:7。
  ratio = 0.3,
  -- prompt と agent の間隔（列）
  gap = 2,
  -- プレビューの最低幅 / 最低高さ。ここを下回るならプレビューを出さない。
  min_preview_width = 36,
  min_preview_height = 6,
  -- prompt の最低幅。比率で計算した値がこれを下回るなら、こちらを優先する。
  min_prompt_width = 30,
  -- agent 一覧の最低幅。これを割るなら横並びをやめて縦積みにする。
  min_list_width = 20,
  -- 一覧の高さ上限。件数が増えてもプレビューを食い潰さない。
  list_max_height = 10,
  draft_height = 8,
  -- プレビューを含むピッカー全体の高さを画面の何割使うか。
  -- 1.0 で画面いっぱい（罫線込みで収まる上限まで）。
  height_ratio = 1,
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

-- 罫線込みで浮きウィンドウを縦に並べるときの、上ウィンドウの下罫線と
-- 下ウィンドウの上罫線に挟まれる行数。
local BORDER_ROWS = 2

function M.calculate(opts)
  opts = opts or {}
  local columns = opts.columns or vim.o.columns
  local lines = opts.lines or vim.o.lines
  local list_count = opts.list_count or 0

  local gap = opt(opts, "gap")
  local draft_height = opt(opts, "draft_height")
  local total_width = math.floor(columns * opt(opts, "width_ratio"))
  -- 一覧が内容として必要な高さ。件数上限で頭打ちにする。
  local list_content_height = math.max(1, math.min(math.max(list_count, 1), opt(opts, "list_max_height")))

  local prompt_width = math.max(opt(opts, "min_prompt_width"), math.floor(total_width * opt(opts, "ratio")))
  local agent_width = total_width - prompt_width - gap
  local horizontal = agent_width >= opt(opts, "min_list_width")

  -- 下段の共通高さ。下書きと一覧の大きい方に揃える。
  local bottom_height = math.max(draft_height, list_content_height)

  -- ピッカー全体の高さ（content の合計）。画面の height_ratio を使い、最低 min_height は確保する。
  -- lines - 2 が上限: 罫線（上下1行ずつ）を画面内に収めるための制限。
  local picker_height =
    math.max(1, math.min(lines - 2, math.max(opt(opts, "min_height"), math.floor(lines * opt(opts, "height_ratio")))))
  local preview_height = picker_height - bottom_height - BORDER_ROWS
  local preview_visible = horizontal and preview_height >= opt(opts, "min_preview_height")

  local col = math.max(0, math.floor((columns - total_width) / 2))

  if not horizontal then
    -- 縦積み: prompt の下に agent。プレビューは出さない。
    -- 全幅で出すので、横並びのときの最低幅（prompt 30）で無駄に狭めない。
    local width = total_width
    local height = draft_height + BORDER_ROWS + list_content_height
    local row = math.max(0, math.floor((lines - height) / 2))
    local draft_row = row
    local list_row = draft_row + draft_height + BORDER_ROWS
    return {
      columns = columns,
      horizontal = false,
      preview_visible = false,
      total_width = width,
      gap = 0,
      row = row,
      col = col,
      picker_height = height,
      -- 上段（プレビューなし）
      preview_width = 0,
      preview_height = 0,
      preview_row = nil,
      preview_col = nil,
      -- 下段（縦積みなので prompt が上、agent が下）
      bottom_row = draft_row,
      bottom_height = bottom_height,
      draft_width = width,
      draft_height = draft_height,
      draft_row = draft_row,
      draft_col = col,
      list_width = width,
      list_height = list_content_height,
      list_row = list_row,
      list_col = col,
    }
  end

  -- 横並び。プレビューが見えないときはピッカー全体が下段だけになる。
  local total_height = preview_visible and picker_height or bottom_height
  local row = math.max(0, math.floor((lines - total_height) / 2))
  local draft_row = row
  if preview_visible then
    draft_row = draft_row + preview_height + BORDER_ROWS
  end
  return {
    columns = columns,
    horizontal = true,
    preview_visible = preview_visible,
    total_width = total_width,
    gap = gap,
    row = row,
    col = col,
    picker_height = total_height,
    -- 上段
    preview_width = preview_visible and total_width or 0,
    preview_height = preview_visible and preview_height or 0,
    preview_row = preview_visible and row or nil,
    preview_col = preview_visible and col or nil,
    -- 下段（prompt | agent）
    bottom_row = draft_row,
    bottom_height = bottom_height,
    draft_width = prompt_width,
    draft_height = bottom_height,
    draft_row = draft_row,
    draft_col = col,
    list_width = agent_width,
    list_height = bottom_height,
    list_row = draft_row,
    list_col = col + prompt_width + gap,
  }
end

return M
