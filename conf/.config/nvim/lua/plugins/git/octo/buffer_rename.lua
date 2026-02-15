-- Buffer name customization for octo buffers (UTF-8 aware, LSP compatible)

local M = {}

-- UTF-8 safe string truncation function
local function utf8_safe_truncate(str, max_chars)
  local chars = {}
  -- Extract UTF-8 characters one by one using pattern matching
  for char in str:gmatch("([^\128-\191][\128-\191]*)") do
    table.insert(chars, char)
    if #chars >= max_chars then
      break
    end
  end
  return table.concat(chars)
end

function M.setup()
  -- Customize issue buffer names: Use issue title instead of number
  -- UTF-8 safe string processing implementation
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufEnter" }, {
    pattern = "octo://*",
    callback = function(event)
      local bufname = vim.api.nvim_buf_get_name(event.buf)

      -- Check if already processed
      if vim.b[event.buf].octo_title_processed then
        return
      end

      -- Extract repository, kind, and number from buffer name
      local repo, kind, number = bufname:match("octo://([^/]+/[^/]+)/([^/]+)/([^/]+)")

      if repo and kind == "issue" and number and tonumber(number) then
        -- Retry function for buffer content loading
        local function try_extract_title(attempt)
          attempt = attempt or 1
          local lines = vim.api.nvim_buf_get_lines(event.buf, 0, -1, false)

          if #lines <= 1 or (#lines == 1 and lines[1] == "") then
            if attempt < 10 then
              vim.defer_fn(function()
                try_extract_title(attempt + 1)
              end, 100 * attempt)
              return
            end
            return
          end

          -- Extract issue title
          local title = nil
          for _, line in ipairs(lines) do
            if line:match("^%s*[^#%s]") then
              title = line:gsub("^%s+", ""):gsub("%s+$", "")
              break
            end
          end

          if title and title ~= "" then
            -- Replace only filesystem-forbidden characters, preserve Japanese
            local clean_title = title:gsub('[/\\:*?"<>|]', "_")
            clean_title = clean_title:gsub("%s+", "_")
            clean_title = clean_title:gsub("_+", "_")
            clean_title = clean_title:gsub("^[_%s]+", "")
            clean_title = clean_title:gsub("[_%s]+$", "")

            -- UTF-8 aware length limit
            local max_chars = 30
            if vim.fn.strchars(clean_title) > max_chars then
              clean_title = utf8_safe_truncate(clean_title, max_chars - 3) .. "..."
            end

            -- Copilot compatibility: Temporarily detach LSP clients
            -- Prevents: RPC[Error] code_name = InvalidParams, message = "Document for URI could not be found:
            local lsp_clients = vim.lsp.get_clients({ bufnr = event.buf })
            local client_ids = {}
            for _, client in ipairs(lsp_clients) do
              table.insert(client_ids, client.id)
              vim.lsp.buf_detach_client(event.buf, client.id)
            end

            -- Change buffer name (with error handling)
            local new_bufname = string.format("octo://%s/%s/%s", repo, kind, clean_title)
            local ok = pcall(vim.api.nvim_buf_set_name, event.buf, new_bufname)

            if not ok then
              -- Handle name collision: Delete existing buffer and retry
              local existing_buf = vim.fn.bufnr(new_bufname)
              if existing_buf ~= -1 and existing_buf ~= event.buf then
                vim.api.nvim_buf_delete(existing_buf, { force = true })
                vim.api.nvim_buf_set_name(event.buf, new_bufname)
              end
            end

            -- Reattach LSP clients (with new buffer name)
            vim.schedule(function()
              for _, client_id in ipairs(client_ids) do
                pcall(vim.lsp.buf_attach_client, event.buf, client_id)
              end
            end)

            vim.b[event.buf].octo_title_processed = true
            vim.b[event.buf].octo_issue_number = tonumber(number) -- Save for reload
          end
        end

        vim.schedule(function()
          try_extract_title(1)
        end)
      end
    end,
  })
end

return M
