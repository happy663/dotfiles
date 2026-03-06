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

-- Create a child issue from the current issue and open the created child issue buffer
function M.create_child_issue_and_open()
  local octo_utils = require("octo.utils")
  local constants = require("octo.constants")
  local gh = require("octo.gh")
  local mutations = require("octo.gh.mutations")
  local octo = require("octo")

  local buffer = octo_utils.get_current_buffer()
  if not buffer or not buffer:isIssue() then
    octo_utils.error("Current buffer is not an issue")
    return
  end

  local parent_issue = buffer:issue()
  if not parent_issue or not parent_issue.id then
    octo_utils.error("Parent issue metadata not found")
    return
  end

  local repo = buffer.repo
  local repo_id = octo_utils.get_repo_id(repo)
  if not repo_id then
    octo_utils.error("Cannot find repo id: " .. repo)
    return
  end

  vim.fn.inputsave()
  local title = vim.trim(vim.fn.input(string.format("Creating child issue in %s. Enter title: ", repo)))
  vim.fn.inputrestore()

  if title == "" then
    octo_utils.error("Issue title cannot be empty")
    return
  end

  vim.fn.inputsave()
  local body = vim.trim(vim.fn.input("Enter issue body (optional): "))
  vim.fn.inputrestore()
  if body == "" then
    body = constants.NO_BODY_MSG
  else
    body = octo_utils.escape_char(body)
  end

  gh.api.graphql({
    query = mutations.create_issue,
    jq = ".data.createIssue.issue",
    F = {
      input = {
        repositoryId = repo_id,
        title = title,
        body = body,
      },
    },
    opts = {
      cb = gh.create_callback({
        success = function(output)
          local child_issue = vim.json.decode(output)

          gh.api.graphql({
            query = mutations.add_subissue,
            fields = {
              parent_id = parent_issue.id,
              child_id = child_issue.id,
            },
            jq = ".data.addSubIssue.subIssue.id",
            opts = {
              cb = gh.create_callback({
                success = function(response_id)
                  if response_id == child_issue.id then
                    octo_utils.info("Child issue created and linked")
                  end
                  octo.create_buffer("issue", child_issue, repo, true, nil)
                  vim.fn.execute("normal! Gk")
                  vim.fn.execute("startinsert")
                end,
                failure = function()
                  octo_utils.error("Issue created but failed to link as a child issue")
                  octo.create_buffer("issue", child_issue, repo, true, nil)
                  vim.fn.execute("normal! Gk")
                  vim.fn.execute("startinsert")
                end,
              }),
            },
          })
        end,
      }),
    },
  })
end

return M
