local M = {}

-- バッファごとの<details>ネスト深さのキャッシュ。changedtickが変わったら再計算する。
-- depth[lnum] はその行を処理する前（直前の行まで）の<details>の深さ。
local details_cache = {}

local function details_depths(bufnr)
  local tick = vim.api.nvim_buf_get_changedtick(bufnr)
  local cached = details_cache[bufnr]
  if cached and cached.tick == tick then
    return cached.depth
  end

  local depth = {}
  local d = 0
  for i, l in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
    depth[i] = d
    if l:match("^%s*<details") then
      d = d + 1
    elseif l:match("^%s*</details>") and d > 0 then
      d = d - 1
    end
  end

  if not cached then
    vim.api.nvim_buf_attach(bufnr, false, {
      on_detach = function()
        details_cache[bufnr] = nil
      end,
    })
  end
  details_cache[bufnr] = { tick = tick, depth = depth }
  return depth
end

-- Markdownの折りたたみ関数（<details>タグとコードブロックの両方に対応）
function M.octo_fold_all()
  local lnum = vim.v.lnum
  local line = vim.fn.getline(lnum)
  local d = details_depths(vim.api.nvim_get_current_buf())[lnum] or 0

  -- <details>タグの処理を優先。ネストした<details>は深さをfoldレベルにする
  if line:match("^%s*<details") then
    return ">" .. (d + 1)
  elseif line:match("^%s*</details>") and d > 0 then
    return "<" .. d
  end

  -- <details>内にいる場合、コードブロックのfoldは作成しない
  if d > 0 then
    return tostring(d)
  end

  -- コードブロックの処理（<details>外のみ）
  if line:match("^```") then
    -- 現在行より前の```の数を数える
    local count = 0
    for i = 1, vim.v.lnum - 1 do
      local prev_line = vim.fn.getline(i)
      if prev_line:match("^```") then
        count = count + 1
      end
    end

    -- 偶数個目（開始タグ）の場合、ブロックの行数をチェック
    if count % 2 == 0 then
      -- 対応する終了タグを探す
      local total_lines = vim.fn.line("$")
      local end_line = nil
      for i = vim.v.lnum + 1, total_lines do
        if vim.fn.getline(i):match("^```") then
          end_line = i
          break
        end
      end

      -- ブロックの行数を計算（開始と終了を除く）
      if end_line then
        local block_lines = end_line - vim.v.lnum - 1
        if block_lines >= 20 then
          return ">1" -- 20行以上なら折りたたみ開始
        end
      end
      return "=" -- 20行未満なら折りたたまない
    else
      -- 奇数個目（終了タグ）の場合、対応する開始タグをチェック
      -- 開始タグで折りたたみ判定済みなので、開始タグが折りたたみ開始なら終了
      for i = vim.v.lnum - 1, 1, -1 do
        if vim.fn.getline(i):match("^```") then
          -- この開始タグが20行以上のブロックかチェック
          if vim.v.lnum - i - 1 >= 20 then
            return "<1" -- 折りたたみ終了
          end
          break
        end
      end
      return "=" -- 折りたたまない
    end
  end

  return "=" -- 前の行のレベルを継承
end

-- 折りたたまれたテキストの表示をカスタマイズ
function M.octo_foldtext()
  local line = vim.fn.getline(vim.v.foldstart)

  -- コードブロックの場合
  if line:match("^```") then
    local lang = line:match("^```(%w+)") or "code"
    local lines_count = vim.v.foldend - vim.v.foldstart - 1
    return "  " .. lang .. " (" .. lines_count .. " lines) ......................................."
  end

  if line:match("<details>") then
    local summary = "詳細"
    -- 折りたたまれた範囲内でsummaryタグを探す
    -- ネストした内側の<details>に入ったら探索をやめる（内側のsummaryを流用しない）
    for i = vim.v.foldstart, vim.v.foldend do
      local l = vim.fn.getline(i)
      if i > vim.v.foldstart and l:match("^%s*<details") then
        break
      end
      local match = l:match("<summary>(.-)</summary>")
      if match then
        summary = match
        break
      end
    end
    return "  " .. summary .. " "
  end

  return vim.fn.foldtext()
end

return M
