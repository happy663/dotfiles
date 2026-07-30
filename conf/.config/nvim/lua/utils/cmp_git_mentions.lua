-- cmp-git の GitHub mentions 補完を、collaborators と contributors の
-- 両方を取得してマージするよう拡張する。
--
-- 背景: デフォルトでは preflight で collaborators 取得権限を判定し、
-- collaborators or contributors のどちらか一方しか取得しない。
-- collaborators 権限があるリポジトリでは、コミット実績-only の人
-- （自分自身を含む）が補完に出ない問題があるため、両方取得して union する。
--
-- 注意: cmp-git の内部モジュールに依存するため、cmp-git のバージョンアップで
-- 壊れる可能性がある。lazy-lock.json の commit を更新する際は要確認。

local command = require("cmp_git.command")
local response = require("cmp_git.response")
local adapter = require("cmp_git.provider.adapters.github")

local M = {}

-- collaborators / contributors の両方を取得して union する。
-- preflight は使わず、mentions_request に member_type を直接指定して並行取得する。
local MEMBER_TYPES = { "collaborators", "contributors" }

local function complete_both(args)
  local bufnr = args.bufnr or vim.api.nvim_get_current_buf()
  local runner = args.runner or command
  local state = { cancelled = false, jobs = {} }

  local controller = {
    command = "cmp_git_mentions_both",
    cancel = function()
      state.cancelled = true
      for _, job in ipairs(state.jobs) do
        if job and job.cancel then
          job:cancel()
        end
      end
    end,
  }

  if args.cache[bufnr] then
    local mentions_cache = args.cache[bufnr]
    args.callback({ items = mentions_cache.items, isIncomplete = mentions_cache.in_progress })
    return nil
  end

  args.cache[bufnr] = { items = {}, in_progress = true }

  local remaining = #MEMBER_TYPES
  local seen = {}

  local function finish_member()
    remaining = remaining - 1
    if remaining <= 0 and not state.cancelled then
      local mentions_cache = args.cache[bufnr]
      mentions_cache.in_progress = false
      args.callback({ items = mentions_cache.items, isIncomplete = false })
    end
  end

  for _, member_type in ipairs(MEMBER_TYPES) do
    local request = args.adapter.mentions_request(args.git_info, args.trigger_char, args.config, {
      context = { member_type = member_type },
      page = 1,
      page_size = math.min(args.config.limit, 100),
    })

    -- build_fallback (list でない方) を使い、success フラグを直接見る。
    -- collaborators API が 403 でも contributors を使うため。
    -- 両方失敗した場合、最後の spec の失敗が success=false で callback に渡る。
    local job = runner.build_fallback(request.commands, function(result, success)
      if state.cancelled then
        return
      end
      if success then
        local list = response.completion_list(result, request.handle_item, request.handle_parsed)
        local mentions_cache = args.cache[bufnr]
        for _, item in ipairs(list.items or {}) do
          -- collaborators と contributors で被る人を login で重複排除
          local key = item.filterText or item.label
          if key and not seen[key] then
            seen[key] = true
            table.insert(mentions_cache.items, item)
          end
        end
        -- 先に返った方から段階的に補完を更新
        args.callback({ items = mentions_cache.items, isIncomplete = true })
      end
      finish_member()
    end)

    if job then
      table.insert(state.jobs, job)
      job:start()
    else
      -- gh / curl ともに実行不可などで job が nil の場合
      finish_member()
    end
  end

  return controller
end

--- cmp-git の GitHub mentions 取得を collaborators + contributors の
--- 両方を取得するよう monkey patch する。
--- cmp-git の setup より前に呼ぶこと。
function M.patch()
  local GitHub = require("cmp_git.sources.github")
  GitHub.complete_mentions = function(self, callback, git_info, trigger_char)
    if not self:is_valid_host(git_info) then
      return false
    end
    local job = complete_both({
      adapter = adapter,
      cache = self.cache.mentions,
      callback = callback,
      config = self.config.mentions,
      git_info = git_info,
      trigger_char = trigger_char,
    })
    return true, job
  end
end

return M
