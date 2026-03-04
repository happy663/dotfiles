local M = {}
-- Markdownの折りたたみ関数（<details>タグとコードブロックの両方に対応）
function M.octo_fold_all()
  local line = vim.fn.getline(vim.v.lnum)

  -- <details>タグの処理を優先
  if line:match("^%s*<details") then
    return ">1"
  elseif line:match("^%s*</details>") then
    return "<1"
  end

  -- <details>タグ内にいるかチェック
  local in_details = false
  for i = vim.v.lnum - 1, 1, -1 do
    local prev_line = vim.fn.getline(i)
    if prev_line:match("^%s*<details") then
      in_details = true
      break
    elseif prev_line:match("^%s*</details>") then
      break
    end
  end

  -- <details>内にいる場合、コードブロックのfoldは作成しない
  if in_details then
    return "="
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
    for i = vim.v.foldstart, vim.v.foldend do
      local l = vim.fn.getline(i)
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
