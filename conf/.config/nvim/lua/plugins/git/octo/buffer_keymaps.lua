local M = {}

function M.octo_buffer_keymaps()
  -- Global function for adding comment with multiple spaces
  function _G.add_comment_multi_space()
    require("octo.commands").add_pr_issue_or_review_thread_comment()
    vim.cmd("normal! o")
    vim.cmd("normal! o")
    vim.cmd("normal! o")
    vim.cmd("normal! o")
    vim.cmd("normal! o")
    vim.cmd("normal! o")
    vim.cmd("normal! 5k")
  end

  -- Buffer-specific keymaps
  vim.keymap.set("n", "<leader>gn", ":Octo comment url<CR>", {
    buffer = true,
    noremap = true,
    silent = true,
  })

  vim.keymap.set("n", "<leader>oa", ":lua add_comment_multi_space()<CR>", {
    buffer = true,
    noremap = true,
    silent = true,
    desc = "Octo: Add comment with extra space",
  })

  vim.keymap.set("n", "<leader>o>", ":Octo comment reply<CR>", {
    buffer = true,
    noremap = true,
    silent = true,
    desc = "Octo: Reply to comment",
  })

  -- Custom reload: Works correctly even after buffer name changes
  -- Uses _G.octo_buffers metadata for reload
  vim.keymap.set("n", "<leader>or", function()
    local current_bufnr = vim.api.nvim_get_current_buf()
    local buffer = _G.octo_buffers and _G.octo_buffers[current_bufnr]
    if buffer and buffer.repo and buffer.kind and buffer.number then
      require("octo").load(buffer.repo, buffer.kind, buffer.number, nil, function(obj)
        vim.api.nvim_buf_call(current_bufnr, function()
          require("octo").create_buffer(buffer.kind, obj, buffer.repo, false, nil)
        end)
        -- Reset flag to re-customize buffer name after reload
        vim.b[current_bufnr].octo_title_processed = false
      end)
    else
      -- Fallback: Try standard reload
      vim.notify("OctoBuffer metadata not found, trying standard reload", vim.log.levels.WARN)
      require("octo.commands").reload()
    end
  end, {
    buffer = true,
    noremap = true,
    silent = true,
    desc = "Octo: Reload (custom)",
  })
end

return M
