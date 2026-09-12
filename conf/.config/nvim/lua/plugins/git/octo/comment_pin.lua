-- Pin / unpin the IssueComment under the cursor on GitHub.
--
-- GitHub added "pinned comments on issues" (2026-02-05). Octo.nvim has no
-- pin/unpin action yet, so this module wraps the GraphQL mutations
-- `pinIssueComment` / `unpinIssueComment` and is wired to `<leader>oP` in
-- octo buffers (see buffer_keymaps.lua).
--
-- Only top-level IssueComment nodes support pinning (PR review comments and
-- discussion comments do not). GitHub models conversation comments on a pull
-- request as IssueComment nodes, so they are covered as well.

local M = {}

-- Current pin state / permissions of a comment.
local COMMENT_STATE_QUERY = [[
  query($id: ID!) {
    node(id: $id) {
      ... on IssueComment {
        id
        isPinned
        viewerCanPin
        viewerCanUnpin
      }
    }
  }
]]

local PIN_COMMENT_MUTATION = [[
  mutation($issueCommentId: ID!) {
    pinIssueComment(input: { issueCommentId: $issueCommentId }) {
      issueComment {
        id
        isPinned
      }
    }
  }
]]

local UNPIN_COMMENT_MUTATION = [[
  mutation($issueCommentId: ID!) {
    unpinIssueComment(input: { issueCommentId: $issueCommentId }) {
      issueComment {
        id
        isPinned
      }
    }
  }
]]

-- Run a pin/unpin mutation and notify about the result.
---@param query string GraphQL mutation text
---@param result_field string mutation field, "pinIssueComment" or "unpinIssueComment"
---@param comment_id string GitHub node id of the comment
---@param verb string e.g. "ピン留め" (used in messages)
local function run_mutation(query, result_field, comment_id, verb)
  local gh = require("octo.gh")
  local octo_utils = require("octo.utils")

  gh.api.graphql({
    query = query,
    F = { issueCommentId = comment_id },
    jq = ("%s.%s.issueComment.id"):format(".data", result_field),
    opts = {
      cb = function(output, stderr, status)
        if status and status ~= 0 then
          local detail = vim.trim(stderr or "")
          if detail == "" then
            detail = vim.trim(output or "")
          end
          octo_utils.error(("コメントを%sできませんでした: %s"):format(verb, detail))
          return
        end
        if output and vim.trim(output) == comment_id then
          octo_utils.info(("コメントを%sしました"):format(verb))
        else
          octo_utils.error(("コメントを%sできませんでした"):format(verb))
        end
      end,
    },
  })
end

-- Toggle the pinned state of the IssueComment under the cursor.
--
-- The buffer is read to learn the current state and the viewer's permission,
-- then the matching mutation is executed. Errors (no comment under the cursor,
-- unsupported comment kind, missing permission, API failure) are reported
-- through vim.notify instead of being thrown.
function M.toggle_pin_comment()
  local gh = require("octo.gh")
  local octo_utils = require("octo.utils")

  local buffer = octo_utils.get_current_buffer()
  if not buffer then
    octo_utils.error("Octoバッファではありません")
    return
  end

  local comment = buffer:get_comment_at_cursor()
  if not comment then
    octo_utils.error("カーソルがコメントの上にありません")
    return
  end

  if comment.kind ~= "IssueComment" then
    octo_utils.error(
      "ピン留めできるのはIssueコメントのみです(レビューコメント等は対象外)"
    )
    return
  end

  if not comment.id or comment.id == -1 then
    octo_utils.error("コメントのIDを取得できません(未保存コメント等)")
    return
  end

  gh.api.graphql({
    query = COMMENT_STATE_QUERY,
    F = { id = comment.id },
    jq = ".data.node",
    opts = {
      cb = function(output, stderr, status)
        if status and status ~= 0 then
          local detail = vim.trim(stderr or "")
          if detail == "" then
            detail = vim.trim(output or "")
          end
          octo_utils.error(("コメントのピン状態を取得できませんでした: %s"):format(detail))
          return
        end

        local ok, state = pcall(vim.json.decode, output or "")
        if not (ok and type(state) == "table" and state.isPinned ~= nil) then
          octo_utils.error("コメントのピン状態を解釈できませんでした")
          return
        end

        if state.isPinned then
          if not state.viewerCanUnpin then
            octo_utils.error("このコメントのピン留めを解除する権限がありません")
            return
          end
          run_mutation(UNPIN_COMMENT_MUTATION, "unpinIssueComment", comment.id, "ピン留め解除")
        else
          if not state.viewerCanPin then
            octo_utils.error("このコメントをピン留めする権限がありません")
            return
          end
          run_mutation(PIN_COMMENT_MUTATION, "pinIssueComment", comment.id, "ピン留め")
        end
      end,
    },
  })
end

return M
