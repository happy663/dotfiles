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
  local function open_issue(issue)
    octo.create_buffer("issue", issue, repo, true, nil)
    vim.fn.execute("normal! Gk")
    vim.fn.execute("startinsert")
  end

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
                  octo.load(repo, "issue", child_issue.number, nil, function(refreshed_issue)
                    open_issue(refreshed_issue)
                  end)
                end,
                failure = function()
                  octo_utils.error("Issue created but failed to link as a child issue")
                  open_issue(child_issue)
                end,
              }),
            },
          })
        end,
      }),
    },
  })
end

-- Flatten the sub-issue tree into a depth-tagged list so that
-- grandchild issues are shown (indented) alongside their parents.
local function flatten_subissues(nodes, depth, acc)
  for _, node in ipairs(nodes) do
    node.depth = depth
    table.insert(acc, node)
    if node.subIssues and node.subIssues.nodes and #node.subIssues.nodes > 0 then
      flatten_subissues(node.subIssues.nodes, depth + 1, acc)
    end
  end
  return acc
end

-- Format a single issue node as a picker line (icon + state + #number + title),
-- indented by its depth in the tree.
local function format_issue_item(node, issue_icons)
  local icon
  if node.state == "OPEN" then
    icon = issue_icons.open[1]
  elseif node.stateReason == "NOT_PLANNED" then
    icon = issue_icons.not_planned[1]
  else
    icon = issue_icons.closed[1]
  end
  local indent = string.rep("  ", node.depth or 0)
  return string.format("%s%s #%d  %s", indent, icon .. node.state, node.number, node.title)
end

-- Sub-issue tree query: the issue itself plus three nested levels of subIssues.
-- `first: 50` per level keeps the node estimate (50^3) under GitHub's 500k cap.
local SUBISSUE_TREE_QUERY = [[
  query($owner: String!, $name: String!, $number: Int!) {
    repository(owner: $owner, name: $name) {
      issue(number: $number) {
        number
        title
        state
        stateReason
        subIssues(first: 50) {
          nodes {
            number
            title
            state
            stateReason
            subIssues(first: 50) {
              nodes {
                number
                title
                state
                stateReason
                subIssues(first: 50) {
                  nodes {
                    number
                    title
                    state
                    stateReason
                  }
                }
              }
            }
          }
        }
      }
    }
  }
]]

-- Open a picker showing the sub-issue tree rooted at ctx.chain[ctx.index].
-- ctx = { repo, owner, name, chain = {root .. current}, index }.
-- Inside the picker, <a-,> widens the root one step toward the topmost ancestor
-- and <a-.> narrows it back toward the current issue, re-rendering each time.
local function open_subissue_picker(ctx)
  local octo_utils = require("octo.utils")
  local gh = require("octo.gh")

  local start = ctx.chain[ctx.index]

  gh.api.graphql({
    query = SUBISSUE_TREE_QUERY,
    fields = {
      owner = ctx.owner,
      name = ctx.name,
      number = start.number,
    },
    jq = ".data.repository.issue",
    opts = {
      cb = gh.create_callback({
        success = function(output)
          local issue = vim.json.decode(output)
          if not issue then
            octo_utils.info("Issue not found")
            return
          end

          -- Show the root issue itself at depth 0, then its sub-issue tree.
          local items = {
            {
              number = issue.number,
              title = issue.title,
              state = issue.state,
              stateReason = issue.stateReason,
              depth = 0,
            },
          }
          local sub_nodes = issue.subIssues and issue.subIssues.nodes or {}
          flatten_subissues(sub_nodes, 1, items)

          local can_widen = ctx.index > 1
          local can_narrow = ctx.index < #ctx.chain
          local hints = {}
          if can_widen then
            hints[#hints + 1] = "a-,:親へ"
          end
          if can_narrow then
            hints[#hints + 1] = "a-.:子へ"
          end
          local hint_str = #hints > 0 and ("  " .. table.concat(hints, " ")) or ""
          local prompt =
            string.format("サブissue (起点 #%d  %d/%d%s):", start.number, ctx.index, #ctx.chain, hint_str)

          local function reopen(picker, new_index)
            picker:close()
            vim.schedule(function()
              ctx.index = new_index
              open_subissue_picker(ctx)
            end)
          end

          local issue_icons = octo_utils.icons.issue
          vim.ui.select(items, {
            prompt = prompt,
            format_item = function(node)
              return format_issue_item(node, issue_icons)
            end,
            snacks = {
              actions = {
                octo_widen_root = function(picker)
                  if ctx.index > 1 then
                    reopen(picker, ctx.index - 1)
                  else
                    octo_utils.info("既に最上位の親(ルート)です")
                  end
                end,
                octo_narrow_root = function(picker)
                  if ctx.index < #ctx.chain then
                    reopen(picker, ctx.index + 1)
                  else
                    octo_utils.info("既にカレントissueです")
                  end
                end,
              },
              win = {
                input = {
                  keys = {
                    ["<a-,>"] = { "octo_widen_root", mode = { "i", "n" } },
                    ["<a-.>"] = { "octo_narrow_root", mode = { "i", "n" } },
                  },
                },
                list = {
                  keys = {
                    ["<a-,>"] = "octo_widen_root",
                    ["<a-.>"] = "octo_narrow_root",
                  },
                },
              },
            },
          }, function(choice)
            if not choice then
              return
            end
            octo_utils.get_issue(choice.number, ctx.repo)
          end)
        end,
      }),
    },
  })
end

-- Resolve repo / owner / name / number from the current octo issue buffer.
-- Returns nil and reports an error when the buffer is not an issue.
local function current_issue_location()
  local octo_utils = require("octo.utils")

  local buffer = octo_utils.get_current_buffer()
  if not buffer or not buffer:isIssue() then
    octo_utils.error("Current buffer is not an issue")
    return nil
  end

  local repo = buffer.repo
  local owner, name = octo_utils.split_repo(repo)
  return { repo = repo, owner = owner, name = name, number = buffer.number }
end

-- List sub-issues starting from the current issue, with the option to widen the
-- root one ancestor at a time (up to the topmost root) from inside the picker.
-- Defaults to the current issue's own sub-tree so deeply nested issues don't
-- flood the list, while the whole tree stays reachable via <a-,>.
function M.list_subissues_and_jump()
  local octo_utils = require("octo.utils")
  local gh = require("octo.gh")

  local loc = current_issue_location()
  if not loc then
    return
  end

  -- Walk the parent chain upward. Sub-issues nest at most 8 levels deep on
  -- GitHub, so an 8-deep parent chain always reaches the root.
  local parent_query = [[
    query($owner: String!, $name: String!, $number: Int!) {
      repository(owner: $owner, name: $name) {
        issue(number: $number) {
          number
          parent { number
            parent { number
              parent { number
                parent { number
                  parent { number
                    parent { number
                      parent { number
                        parent { number }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  ]]

  gh.api.graphql({
    query = parent_query,
    fields = {
      owner = loc.owner,
      name = loc.name,
      number = loc.number,
    },
    jq = ".data.repository.issue",
    opts = {
      cb = gh.create_callback({
        success = function(output)
          local issue = vim.json.decode(output)
          if not issue then
            octo_utils.error("Issue not found")
            return
          end

          -- Build the ancestor chain ordered root-first, current-last. Inserting
          -- at the front while walking parents yields {root, ..., current}.
          -- vim.json.decode maps JSON null to vim.NIL (userdata), not nil, so
          -- guard with a table check to stop at the topmost real parent.
          local chain = {}
          local node = issue
          while type(node) == "table" and node.number do
            table.insert(chain, 1, { number = node.number })
            node = node.parent
          end

          open_subissue_picker({
            repo = loc.repo,
            owner = loc.owner,
            name = loc.name,
            chain = chain,
            index = #chain, -- start at the current issue
          })
        end,
      }),
    },
  })
end

return M
