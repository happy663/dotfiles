return {
  {
    "CRAG666/code_runner.nvim",
    cond = vim.g.not_in_vscode,
    config = function()
      require("code_runner").setup({
        filetype = {
          java = {
            "cd $dir &&",
            "javac $fileName &&",
            "java $fileNameWithoutExt",
          },
          python = "python3 -u",
          typescript = "deno run",
          rust = {
            "cd $dir &&",
            "rustc $fileName &&",
            "$dir/$fileNameWithoutExt",
          },
          c = { "cd $dir && gcc $fileName -o $fileNameWithoutExt && ./$fileNameWithoutExt" },
        },
      })
    end,
  },
  {
    "glidenote/memolist.vim",
    cond = vim.g.not_in_vscode,
    config = function()
      vim.g.memolist_path = "~/.memolist/memo"
      vim.g.memolist_memo_suffix = "md"
      vim.g.memolist_fzf = 1
      vim.g.memolist_template_dir_path = "~/.memolist/memotemplates"
    end,
  },
  {
    "iamcco/markdown-preview.nvim",
    cond = vim.g.not_in_vscode,
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = function()
      vim.fn["mkdp#util#install"]()
    end,
  },
  {
    "lervag/vimtex",
    cond = vim.g.not_in_vscode,
    lazy = false,
    tag = "v2.15",
    init = function()
      vim.g.vimtex_view_general_viewer = "zathura"
      vim.g.vimtex_quickfix_open_on_warning = 0
    end,
  },
  {
    "aznhe21/actions-preview.nvim",
    cond = vim.g.not_in_vscode,
    config = function()
      vim.keymap.set({ "v", "n" }, "<Leader>ca", require("actions-preview").code_actions, {
        noremap = true,
        silent = true,
        desc = "Code Actions",
      })
      local hl = require("actions-preview.highlight")
      require("actions-preview").setup({
        highlight_command = {
          hl.delta(),
        },
        telescope = {
          sorting_strategy = "ascending",
          layout_strategy = "vertical",
          layout_config = {
            width = 0.8,
            height = 0.9,
            prompt_position = "top",
            preview_cutoff = 20,
            preview_height = function(_, _, max_lines)
              return max_lines - 15
            end,
          },
        },
      })
    end,
  },
  {
    "simeji/winresizer",
    cond = vim.g.not_in_vscode,
  },
  {
    "skanehira/gyazo.vim",
    cond = vim.g.not_in_vscode,
  },
  {
    "vinnymeller/swagger-preview.nvim",
    cond = vim.g.not_in_vscode,
    config = function()
      require("swagger-preview").setup({
        port = 8003,
        host = "localhost",
      })
    end,
  },
  {
    "folke/which-key.nvim",
    cond = vim.g.not_in_vscode,
    event = "VeryLazy",
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    },
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "Buffer Local Keymaps (which-key)",
      },
    },
  },
  {
    "thinca/vim-qfreplace",
    cond = vim.g.not_in_vscode,
  },
  -- jupytext change(ipynb -> py)
  {
    "GCBallesteros/jupytext.nvim",
    cond = vim.g.not_in_vscode,
    config = true,
    ft = "ipynb",
    lazy = false,
  },
  --  cell run
  {
    -- "GCBallesteros/NotebookNavigator.nvim",
    -- keys = {
    --   {
    --     "]h",
    --     function()
    --       require("notebook-navigator").move_cell("d")
    --     end,
    --   },
    --   {
    --     "[h",
    --     function()
    --       require("notebook-navigator").move_cell("u")
    --     end,
    --   },
    --   { "<leader>rc", "<cmd>lua require('notebook-navigator').run_cell()<cr>" },
    --   { "<leader>rm", "<cmd>lua require('notebook-navigator').run_and_move()<cr>" },
    -- },
    -- dependencies = {
    --   "echasnovski/mini.comment",
    --   "anuvyklack/hydra.nvim",
    --   {
    --     "benlubas/molten-nvim",
    --     version = "^1.0.0", -- use version <2.0.0 to avoid breaking changes
    --     dependencies = {
    --       {
    --         "3rd/image.nvim",
    --         opts = {
    --           backend = "kitty", -- whatever backend you would like to use
    --           max_width = 500,
    --           max_height = 500,
    --           max_height_window_percentage = math.huge,
    --           max_width_window_percentage = math.huge,
    --           window_overlap_clear_enabled = true, -- toggles images when windows are overlapped
    --           window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
    --         },
    --       },
    --     },
    --     build = ":UpdateRemotePlugins",
    --     -- cmd = "MoltenInit",
    --     init = function()
    --       vim.g.python3_host_prog = vim.fn.expand("~/.virtualenvs/neovim/bin/python3")
    --       -- these are examples, not defaults. Please see the readme
    --       vim.g.molten_image_provider = "image.nvim"
    --       vim.g.molten_output_win_max_height = 500
    --       -- vim.g.molten_auto_open_output = true
    --       -- vim.g.molten_virt_text_output = true
    --       -- vim.g.molten_virt_lines_off_by_1 = true
    --     end,
    --   },
    -- },
    -- cond = vim.g.not_in_vscode,
    -- event = "VeryLazy",
    -- config = function()
    --   local nn = require("notebook-navigator")
    --   nn.setup({ activate_hydra_keys = "<leader>h", repl_provider = "molten" })
    -- end,
  },
  {
    "folke/zen-mode.nvim",
    cond = vim.g.not_in_vscode,
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    },
    config = {
      vim.keymap.set("n", "<leader>zz", "<cmd>ZenMode<cr>", { noremap = true, silent = true }),
    },
  },
  {
    -- "ixru/nvim-markdown",
    -- cond = vim.g.not_in_vscode,
  },
  {
    "scalameta/nvim-metals",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    ft = { "scala", "sbt", "java" },
    opts = function()
      local metals_config = require("metals").bare_config()
      metals_config.on_attach = function(_, _)
        -- your on_attach function
      end

      return metals_config
    end,
    config = function(self, metals_config)
      local nvim_metals_group = vim.api.nvim_create_augroup("nvim-metals", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        pattern = self.ft,
        callback = function()
          require("metals").initialize_or_attach(metals_config)
        end,
        group = nvim_metals_group,
      })
    end,
  },
  {
    "marcussimonsen/let-it-snow.nvim",
    cmd = "LetItSnow", -- Wait with loading until command is run
    opts = {},
  },
  {
    "happy663/discord-send.nvim",
    cond = vim.g.not_in_vscode,
    config = function()
      require("discord-send.discord").setup({})
    end,
  },
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      local codecompanion = require("codecompanion")
      codecompanion.setup({
        prompt = {},
        opts = {
          language = "Japanese",
        },
        strategies = {
          chat = {
            keymaps = {
              send = {
                modes = {
                  n = { "<C-S>" }, -- 送信を<C-s>のみに変更
                  i = { "<C-S>" },
                },
              },
            },
          },
        },

        prompt_library = {
          ["Refactor Code"] = {
            strategy = "chat",
            description = "Refactor the selected code to improve its structure and quality",
            opts = {
              index = 12,
              is_default = true,
              is_slash_cmd = false,
              modes = { "v" },
              short_name = "refactor",
              auto_submit = true,
              user_prompt = false,
              stop_context_insertion = true,
            },
            prompts = {
              {
                role = "system",
                content = [[You are an expert in code refactoring. When refactoring code, follow these principles:
                1. Apply SOLID principles where appropriate
                2. Use design patterns effectively
                3. Improve code modularity and reusability
                4. Enhance readability and maintainability
                5. Remove code duplication
                6. Follow language-specific best practices
                7. Preserve the original functionality
                Return only the refactored code without explanations.]],
                opts = {
                  visible = false,
                },
              },
              {
                role = "user",
                content = function(context)
                  local code = require("codecompanion.helpers.actions").get_code(
                    context.start_line,
                    context.end_line,
                    { show_line_numbers = true }
                  )

                  return string.format(
                    [[Please refactor this %s code:
                        ```%s
                        %s
                        ```]],
                    context.filetype,
                    context.filetype,
                    code
                  )
                end,
                opts = {
                  contains_code = true,
                },
              },
            },
          },
          ["Refactor Code Inline"] = {
            strategy = "inline",
            description = "Refactor the selected code to improve its structure and quality",
            opts = {
              index = 12,
              is_default = true,
              is_slash_cmd = false,
              modes = { "v" },
              short_name = "refactorfix",
              auto_submit = true,
              user_prompt = false,
              stop_context_insertion = true,
            },
            prompts = {
              {
                role = "system",
                content = [[You are an expert in code refactoring. When refactoring code, follow these principles:
                1. Apply SOLID principles where appropriate
                2. Use design patterns effectively
                3. Improve code modularity and reusability
                4. Enhance readability and maintainability
                5. Remove code duplication
                6. Follow language-specific best practices
                7. Preserve the original functionality
                Return only the refactored code without explanations.]],
                opts = {
                  visible = false,
                },
              },
              {
                role = "user",
                content = function(context)
                  local code = require("codecompanion.helpers.actions").get_code(
                    context.start_line,
                    context.end_line,
                    { show_line_numbers = true }
                  )
                  return string.format(
                    [[Please refactor this %s code:
                        ```%s
                        %s
                        ```]],
                    context.filetype,
                    context.filetype,
                    code
                  )
                end,
                opts = {
                  contains_code = true,
                },
              },
            },
          },
          ["Fix LSP Inline"] = { -- 新しいプロンプト名
            strategy = "inline",
            description = "Fix LSP issues with inline changes",
            opts = {
              index = 11, -- 既存のプロンプトの後ろの番号を使用
              is_default = true,
              is_slash_cmd = false,
              modes = { "v" },
              short_name = "lspfix", -- 新しいショートネーム
              auto_submit = true,
              user_prompt = false,
              stop_context_insertion = true,
            },
            prompts = {
              {
                role = "system",
                content = [[You are an expert coder focusing on fixing LSP diagnostic issues. When fixing code:
                1. Only provide the corrected code
                2. Ensure all LSP diagnostics are resolved
                3. Maintain the original code style
                4. Only include necessary changes
                5. Return raw code only without explanations or markdown]],
                opts = {
                  visible = false,
                },
              },
              {
                role = "user",
                content = function(context)
                  local diagnostics = require("codecompanion.helpers.actions").get_diagnostics(
                    context.start_line,
                    context.end_line,
                    context.bufnr
                  )

                  local code = require("codecompanion.helpers.actions").get_code(
                    context.start_line,
                    context.end_line,
                    { show_line_numbers = true }
                  )

                  return string.format(
                    [[Fix this %s code according to the LSP diagnostics:
                    LSP Diagnostics:
                    %s

                    Code:
                    %s]],
                    context.filetype,
                    vim.inspect(diagnostics),
                    code
                  )
                end,
                opts = {
                  contains_code = true,
                },
              },
            },
          },
        },
      })

      vim.keymap.set({
        "n",
        "v",
      }, "<leader>ccfr", "<cmd>CodeCompanion /refactorfix<cr>", { noremap = true, silent = true })
      vim.keymap.set({
        "n",
        "v",
      }, "<leader>ccfl", "<cmd>CodeCompanion /lspfix<cr>", { noremap = true, silent = true })
      vim.keymap.set({
        "n",
        "v",
      }, "<leader>ccl", "<cmd>CodeCompanion /lsp<cr>", { noremap = true, silent = true })
      vim.keymap.set({ "n", "v" }, "<leader>ccr", "<cmd>CodeCompanion /refactor<cr>", { noremap = true, silent = true })

      vim.keymap.set("n", "<leader>ccc", "<cmd>CodeCompanionChat<cr>", { noremap = true, silent = true })
      vim.keymap.set("v", "<leader>ccc", "<cmd>CodeCompanionChat<cr>", { noremap = true, silent = true })
      vim.keymap.set("v", "<leader>ccff", "<cmd>CodeCompanion /fix<cr>", { noremap = true, silent = true })
      vim.keymap.set("n", "<leader>cce", "<cmd>CodeCompanion /explain<cr>", { noremap = true, silent = true })
      vim.keymap.set("v", "<leader>cce", "<cmd>CodeCompanion /explain<cr>", { noremap = true, silent = true })
      vim.keymap.set("n", "<leader>cca", "<cmd>CodeCompanionActions<cr>", { noremap = true, silent = true })
      vim.keymap.set("v", "<leader>cca", "<cmd>CodeCompanionActions<cr>", { noremap = true, silent = true })
      vim.keymap.set("n", "<leader>cct", "<cmd>CodeCompanionChat Toggle<cr>", { noremap = true, silent = true })
      vim.keymap.set("v", "<leader>cct", "<cmd>CodeCompanionChat Toggle<cr>", { noremap = true, silent = true })
      -- 選択したチャットを現在のチャットバッファーに追加
      vim.keymap.set("v", "ga", "<cmd>CodeCompanionChat Add<cr>", { noremap = true, silent = true })

      -- コマンドラインで'cc'を'CodeCompanion'に展開
      vim.cmd([[cab cc CodeCompanion]])
    end,
  },
}
