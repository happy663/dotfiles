local utils = require("utils")
-- Load environment variables from .env file
utils.load_env("~/.config/nvim/.env")

--- Sends an article to Hitonowa platform
-- @param title string: The title of the article
-- @param content string: The main content of the article
-- @param args table: Optional tags for the article
local function send_to_hitonowa(title, content, args)
  local curl = require("plenary.curl")
  -- Get API key from environment variables
  local api_key = vim.fn.getenv("HITONOWA_API_KEY")
  if api_key == "" then
    vim.notify("HITONOWA_API_KEYが設定されていません", vim.log.levels.ERROR)
    return
  end
  -- Prepare the request payload
  local data = {
    title = title,
    content = content,
    tags = args or {},
  }
  local end_point = "https://api.hitonowa.work/notes/articles"

  -- Make POST request to Hitonowa API
  local response = curl.post(end_point, {
    headers = {
      ["Content-Type"] = "application/json",
      ["Authorization"] = "Bearer " .. api_key,
    },
    body = vim.fn.json_encode(data),
  })

  -- Handle response status
  if response.status >= 200 and response.status < 300 then
    vim.notify("Hitonowaに送信しました", vim.log.levels.INFO)
  else
    vim.notify("Hitonowa送信エラー" .. response.body, vim.log.levels.ERROR)
  end
end

--- Processes the current buffer to extract article title and content
-- @param bufnr number: Buffer number to process
-- @return string, string: Returns title and content if successful, nil otherwise
local function create_article_data(bufnr)
  -- Get all lines from the buffer
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  -- Extract title from the first line starting with #
  local title = vim
    .tbl_filter(function(line)
      return line:match("^#")
    end, lines)[1]
    :gsub("^#%s+", "") or ""

  -- Validate title
  if vim.trim(title) == "" then
    vim.notify("記事のタイトルを入力してください", vim.log.levels.WARN)
    return
  end
  -- コンテンツからタイトル行を削除
  -- Remove title line and join content
  local content = table.concat(lines, "\n"):gsub("^#%s+.-\n", "")

  -- Validate content
  if vim.trim(content) == "" then
    vim.notify("記事のコンテンツを入力してください", vim.log.levels.WARN)
    return
  end

  return title, content
end

-- Register the HitonowaPost command
-- Usage: :HitonowaPost [tag1] [tag2] ...
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
