-- Helper functions for octo.nvim plugin

local M = {}

-- Get current repository name using gh CLI
function M.get_current_repo()
  local result = vim
    .system({
      "gh",
      "repo",
      "view",
      "--json",
      "nameWithOwner",
      "-q",
      ".nameWithOwner",
    }, {
      text = true,
    })
    :wait()

  if result.code ~= 0 then
    vim.notify("Error getting current repo: " .. result.stderr, vim.log.levels.ERROR)
    return nil
  end

  return vim.trim(result.stdout)
end

-- Issue search helper function
function M.search_issues(search_type)
  local prompt_map = {
    title = "Search in title: ",
    body = "Search in body: ",
    all = "Search issues: ",
  }

  local search_suffix = {
    title = " in:title",
    body = " in:body",
    all = "",
  }

  local query = vim.trim(vim.fn.input(prompt_map[search_type]))
  if query == "" then
    vim.notify("Search query cannot be empty.", vim.log.levels.ERROR)
    return
  end

  local current_repo = M.get_current_repo()
  if not current_repo then
    return
  end

  vim.cmd("Octo search repo:" .. current_repo .. " " .. query .. search_suffix[search_type])
end

return M
