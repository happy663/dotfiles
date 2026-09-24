-- Send octo picker entries to the quickfix list together with their titles.
--
-- telescope's `send_to_qflist` only knows `entry.value` (the issue/PR number),
-- so unopened issues end up in the quickfix list as bare numbers. The octo
-- entries carry the fetched object in `entry.obj`, so build the list ourselves
-- and show `<repo>#<number>` plus the title.

local M = {}

---@param entry table telescope entry
---@return table|nil quickfix item
local function to_qf_item(entry)
  local obj = entry.obj
  if type(obj) ~= "table" or type(obj.title) ~= "string" or obj.title == "" then
    return nil
  end

  local filename = entry.filename
  if type(filename) ~= "string" or not filename:match("^octo://") then
    return nil
  end

  local repo = entry.repo or filename:match("^octo://([^/]+/[^/]+)/")
  local repo_tail = repo and repo:match("([^/]+)$") or "octo"

  return {
    filename = filename,
    -- `module` replaces the filename in the quickfix window, so the long
    -- octo:// URI does not eat the whole line. Jumping still uses `filename`.
    module = string.format("%s#%s", repo_tail, tostring(entry.value)),
    lnum = 0,
    col = 0,
    text = obj.title,
  }
end

--- Collect the octo entries of the current picker as quickfix items.
---@param prompt_bufnr integer
---@return table|nil items nil when the picker holds no octo entries
function M.collect_items(prompt_bufnr)
  local items = {}
  require("telescope.actions.utils").map_entries(prompt_bufnr, function(entry)
    local item = to_qf_item(entry)
    if item then
      table.insert(items, item)
    end
  end)

  if vim.tbl_isempty(items) then
    return nil
  end
  return items
end

--- Replace the quickfix list with the octo entries of the current picker.
---@param prompt_bufnr integer
---@return boolean handled false when the picker is not an octo picker
function M.send_from_picker(prompt_bufnr)
  local ok, items = pcall(M.collect_items, prompt_bufnr)
  if not ok or not items then
    return false
  end

  require("telescope.actions").close(prompt_bufnr)
  vim.fn.setqflist({}, " ", { title = "Octo", items = items })
  vim.cmd("copen")
  return true
end

return M
