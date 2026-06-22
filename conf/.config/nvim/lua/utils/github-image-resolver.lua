local M = {}

local CACHE_DIR = vim.fn.stdpath("cache") .. "/snacks/github-images"
local PLACEHOLDER_PATH = CACHE_DIR .. "/_placeholder.png"
local downloading = {}
local rerender_pending = false

local function is_github_asset_url(src)
  return src:match("github%.com/.+/assets/")
    or src:match("github%.com/user%-attachments/assets/")
    or src:match("private%-user%-images%.githubusercontent%.com/")
end

local function get_cache_path(src)
  local hash = vim.fn.sha256(src):sub(1, 16)
  local ext = src:match("%.(%w+)%??[^/]*$") or "png"
  if not vim.tbl_contains({ "png", "jpg", "jpeg", "gif", "webp", "svg", "bmp" }, ext) then
    ext = "png"
  end
  return CACHE_DIR .. "/" .. hash .. "." .. ext
end

local function ensure_placeholder()
  if vim.fn.filereadable(PLACEHOLDER_PATH) == 1 then
    return true
  end
  vim.fn.mkdir(CACHE_DIR, "p")
  local result = vim.system({ "magick", "-size", "1x1", "xc:none", PLACEHOLDER_PATH }):wait()
  if result.code ~= 0 then
    vim.system({ "convert", "-size", "1x1", "xc:none", PLACEHOLDER_PATH }):wait()
  end
  return vim.fn.filereadable(PLACEHOLDER_PATH) == 1
end

local function schedule_rerender()
  if rerender_pending then
    return
  end
  rerender_pending = true
  vim.defer_fn(function()
    rerender_pending = false
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == "octo" then
        local modified = vim.bo[buf].modified
        local last = vim.api.nvim_buf_line_count(buf) - 1
        local line = vim.api.nvim_buf_get_lines(buf, last, last + 1, false)[1] or ""
        vim.api.nvim_buf_set_lines(buf, last, last + 1, false, { line .. " " })
        vim.api.nvim_buf_set_lines(buf, last, last + 1, false, { line })
        vim.bo[buf].modified = modified
      end
    end
  end, 300)
end

local function download_async(src, dest)
  if downloading[src] then
    return
  end
  downloading[src] = true

  vim.system({ "gh", "auth", "token" }, { text = true }, function(token_result)
    if token_result.code ~= 0 or not token_result.stdout then
      downloading[src] = nil
      return
    end
    local token = vim.trim(token_result.stdout)

    vim.system({
      "curl",
      "-sL",
      "-H",
      "Authorization: token " .. token,
      "-H",
      "Accept: application/octet-stream",
      "-o",
      dest,
      src,
    }, { text = false }, function(dl_result)
      downloading[src] = nil
      vim.schedule(function()
        if dl_result.code == 0 and vim.fn.getfsize(dest) > 0 then
          schedule_rerender()
        end
      end)
    end)
  end)
end

function M.resolve(_, src)
  if not is_github_asset_url(src) then
    return nil
  end

  vim.fn.mkdir(CACHE_DIR, "p")
  local cached = get_cache_path(src)

  if vim.fn.filereadable(cached) == 1 and vim.fn.getfsize(cached) > 0 then
    return cached
  end

  download_async(src, cached)

  if ensure_placeholder() then
    return PLACEHOLDER_PATH
  end
  return nil
end

return M
