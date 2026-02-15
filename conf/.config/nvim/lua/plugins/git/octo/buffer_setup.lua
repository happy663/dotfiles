
local M = {}

local function setup_buffer_keymaps(bufnr)
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
  vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>gn", ":Octo comment url<CR>", {
    noremap = true,
    silent = true,
  })

  vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>oa", ":lua add_comment_multi_space()<CR>", {
    noremap = true,
    silent = true,
    desc = "Octo: Add comment with extra space",
  })

  vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>o>", ":Octo comment reply<CR>", {
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
    buffer = bufnr,
    noremap = true,
    silent = true,
    desc = "Octo: Reload (custom)",
  })
end

function M.setup()
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "octo",
    callback = function()
      -- Basic buffer settings
      vim.cmd([[setlocal wrap]])
      vim.cmd([[setlocal linebreak]])

      -- Register treesitter for render-markdown
      -- Use markdown parser in octo buffers
      vim.treesitter.language.register("markdown", "octo")

      -- Adjust Treesitter's conceal feature (always display code blocks)
      vim.schedule(function()
        vim.opt_local.conceallevel = 0
        -- Or, to only disable conceal at cursor position:
        -- vim.opt_local.conceallevel = 2
        -- vim.opt_local.concealcursor = "" -- Disable conceal in all modes
      end)

      -- Ensure nvim-markdown ftplugin runs
      vim.schedule(function()
        vim.b.did_ftplugin = nil
        vim.cmd("runtime! ftplugin/markdown.vim")
      end)

      -- Markdown FileType autocmd placeholder
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "markdown",
        callback = function() end,
      })

      -- URL highlighting
      vim.fn.matchadd("Underlined", "https\\?://[^ )>]*")
      -- Or custom highlight group
      vim.cmd([[
        highlight MarkdownURL guifg=#569CD6 gui=underline ctermfg=75 cterm=underline
      ]])
      vim.fn.matchadd("MarkdownURL", "https\\?://[^ )>]*")

      -- Fold settings for Octo buffer
      vim.schedule(function()
        vim.opt_local.foldmethod = "expr"
        vim.opt_local.foldexpr = "v:lua.octo_fold_all()"
        vim.opt_local.foldlevel = 0
        vim.opt_local.foldtext = "v:lua.octo_foldtext()"
        vim.opt_local.conceallevel = 0
        -- Ensure fold display is visible
        vim.opt_local.fillchars:append({ fold = " " })

        -- Prevent nvim-markdown's loadview from overwriting highlight settings
        vim.api.nvim_set_hl(0, "Folded", {
          fg = "#82aaff", -- Bright blue (harmonizes with tokyonight-moon)
          bg = "#1e2030", -- Slightly darker background
          italic = true,
        })

        vim.api.nvim_set_hl(0, "FoldColumn", {
          fg = "#636da6",
          bg = "NONE",
        })
      end)

      -- Reapply settings after render-markdown loads
      vim.defer_fn(function()
        if vim.bo.filetype == "octo" then
          vim.opt_local.foldtext = "v:lua.octo_foldtext()"
          vim.opt_local.conceallevel = 0
        end
      end, 200)

      -- Setup buffer-specific keymaps
      setup_buffer_keymaps(0)
    end,
  })
end

return M
