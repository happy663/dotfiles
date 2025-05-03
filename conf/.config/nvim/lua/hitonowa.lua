local utils = require("utils")
utils.load_env("~/.config/nvim/.env")

local function send_to_hitonowa(title, content, args)
  local curl = require("plenary.curl")
  local api_key = vim.fn.getenv("HITONOWA_API_KEY")
  if api_key == "" then
    vim.notify("HITONOWA_API_KEYが設定されていません", vim.log.levels.ERROR)
    return
  end
  local data = {
    title = title,
    content = content,
    tags = args or {},
  }
  local end_point = "https://api.hitonowa.work/notes/articles"

  local response = curl.post(end_point, {
    headers = {
      ["Content-Type"] = "application/json",
      ["Authorization"] = "Bearer " .. api_key,
    },
    body = vim.fn.json_encode(data),
  })

  if response.status >= 200 and response.status < 300 then
    vim.notify("Hitonowaに送信しました", vim.log.levels.INFO)
  else
    vim.notify("Hitonowa送信エラー" .. response.body, vim.log.levels.ERROR)
  end
end

local function create_article_data(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local title = vim
    .tbl_filter(function(line)
      return line:match("^#")
    end, lines)[1]
    :gsub("^#%s+", "") or ""

  if vim.trim(title) == "" then
    vim.notify("記事のタイトルを入力してください", vim.log.levels.WARN)
    return
  end
  -- コンテンツからタイトル行を削除
  local content = table.concat(lines, "\n"):gsub("^#%s+.-\n", "")

  if vim.trim(content) == "" then
    vim.notify("記事のコンテンツを入力してください", vim.log.levels.WARN)
    return
  end

  return title, content
end

vim.api.nvim_create_user_command("HitonowaPost", function(opts)
  local bufnr = vim.api.nvim_get_current_buf()
  local title, content = create_article_data(bufnr)
  if not title or not content then
    return
  end
  send_to_hitonowa(title, content, opts.fargs)
end, {
  desc = "Send to Hitonowa",
  nargs = "*",
})
