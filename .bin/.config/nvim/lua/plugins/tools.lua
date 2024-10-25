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
    "CopilotC-Nvim/CopilotChat.nvim",
    branch = "canary",
    dependencies = {
      { "zbirenbaum/copilot.lua" }, -- or github/copilot.vim
      { "nvim-lua/plenary.nvim" }, -- for curl, log wrapper
    },
    opts = {
      -- debug = true, -- Enable debugging
      -- See Configuration section for rest
    },
    config = function()
      local select = require("CopilotChat.select")
      require("CopilotChat").setup({
        -- プロンプトの設定
        -- デフォルトは英語なので日本語でオーバーライドしています
        mappings = {
          complete = {
            detail = "@<Tab>",
            insert = "<S-Tab>",
          },
        },
        prompts = {
          MyCustomPrompt = {
            prompt = "どう機能するか教えてください",
            mapping = "<leader>ccmc",
            description = "My custom prompt description",
            selection = require("CopilotChat.select").visual,
          },
          Commit = {
            prompt = "コミットメッセージをコミット規約に従って記述します。タイトルは最大50文字で、メッセージは72文字で折り返す。メッセージ全体をgitcommit言語でコードブロックにラップする。",
            selection = select.staged,
          },
          CommitStaged = {
            prompt = "ステージングされた変更をコミットします。コミットメッセージをコミット規約に従って記述します。タイトルは最大50文字で、メッセージは72文字で折り返す。メッセージ全体をgitcommit言語でコードブロックにラップする。",
            selection = function(source)
              return select.gitdiff(source, true)
            end,
          },
          Explain = {
            prompt = "/COPILOT_EXPLAIN カーソル上のコードの説明を段落をつけて書いてください。",
            selection = select.visual,
          },
          Tests = {
            prompt = "/COPILOT_TESTS カーソル上のコードの詳細な単体テスト関数を書いてください。",
            selection = select.visual,
          },
          Fix = {
            prompt = "/COPILOT_FIX このコードには問題があります。バグを修正したコードに書き換えてください。",
            selection = select.visual,
          },
          Optimize = {
            prompt = "/COPILOT_REFACTOR 選択したコードを最適化し、パフォーマンスと可読性を向上させてください。",
            selection = select.visual,
          },
          Docs = {
            prompt = "/COPILOT_REFACTOR 選択したコードのドキュメントを書いてください。ドキュメントをコメントとして追加した元のコードを含むコードブロックで回答してください。使用するプログラミング言語に最も適したドキュメントスタイルを使用してください（例：JavaScriptのJSDoc、Pythonのdocstringsなど）",
            selection = select.visual,
          },
          FixDiagnostic = {
            prompt = "ファイル内の次のような診断上の問題を解決してください：",
            selection = select.diagnostics,
          },
          Review = {
            prompt = "/COPILOT_REVIEW コードレビューを行います。",
            selection = select.visual,
          },
        },
      })
      -- CopilotChatを開くキーバインドを追加する

      vim.keymap.set("n", "<leader>cco", function()
        require("CopilotChat").ask()
      end)

      vim.keymap.set("n", "<leader>ccq", function()
        local input = vim.fn.input("Quick Chat: ")
        if input ~= "" then
          require("CopilotChat").ask(input, { selection = require("CopilotChat.select").buffer })
        end
      end)
      vim.keymap.set("n", "<leader>ccp", function()
        local actions = require("CopilotChat.actions")
        require("CopilotChat.integrations.telescope").pick(actions.prompt_actions())
      end)
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
      vim.keymap.set({ "v", "n" }, "<Leader>ca", require("actions-preview").code_actions)
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
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    cond = vim.g.not_in_vscode,
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local harpoon = require("harpoon")
      harpoon:setup()

      local conf = require("telescope.config").values

      local function toggle_telescope(harpoon_files)
        local file_paths = {}

        for _, item in ipairs(harpoon_files.items) do
          table.insert(file_paths, item.value)
        end

        local make_finder = function()
          local paths = {}

          for _, item in ipairs(harpoon_files.items) do
            table.insert(paths, item.value)
          end

          return require("telescope.finders").new_table({
            results = paths,
          })
        end
        require("telescope.pickers")
          .new({}, {
            prompt_title = "Harpoon",
            finder = require("telescope.finders").new_table({
              results = file_paths,
            }),
            previewer = false,
            sorter = conf.generic_sorter({}),
            layout_strategy = "center",
            layout_config = {
              preview_cutoff = 1, -- Preview should always show (unless previewer = false)
              width = function(_, max_columns, _)
                return math.min(max_columns, 80)
              end,

              height = function(_, _, max_lines)
                return math.min(max_lines, 15)
              end,
            },
            borderchars = {
              prompt = { "─", "│", " ", "│", "╭", "╮", "│", "│" },
              results = { "─", "│", "─", "│", "├", "┤", "╯", "╰" },
              preview = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
            },
            attach_mappings = function(prompt_buffer_number, map)
              map("i", "<c-d>", function()
                local state = require("telescope.actions.state")
                local selected_entry = state.get_selected_entry()
                local current_picker = state.get_current_picker(prompt_buffer_number)

                harpoon:list():remove(selected_entry)
                current_picker:refresh(make_finder())
              end)

              return true
            end,
          })
          :find()
      end

      vim.keymap.set("n", "<leader>qq", function()
        toggle_telescope(harpoon:list())
      end)

      vim.keymap.set("n", "<leader>qa", function()
        harpoon:list():add()
      end)
      vim.keymap.set("n", "<C-1>", function()
        harpoon:list():select(1)
      end)
      vim.keymap.set("n", "<C-2>", function()
        harpoon:list():select(2)
      end)
      vim.keymap.set("n", "<C-3>", function()
        harpoon:list():select(3)
      end)
      vim.keymap.set("n", "<C-4>", function()
        harpoon:list():select(4)
      end)
    end,
  },
  {
    "folke/persistence.nvim",
    event = "BufReadPre", -- this will only start session saving when an actual file was opened
    cond = vim.g.not_in_vscode,
    config = function()
      require("persistence").setup({
        dir = vim.fn.stdpath("state") .. "/session/",
        need = 1,
        branch = true,
      })
      -- load the session for the current directory
      vim.keymap.set("n", "<leader>qs", function()
        require("persistence").load()
      end)

      -- select a session to load
      vim.keymap.set("n", "<leader>qS", function()
        require("persistence").select()
      end)

      -- load the last sessionJ
      vim.keymap.set("n", "<leader>ql", function()
        require("persistence").load({ last = true })
      end)

      -- stop Persistence => session won't be saved on exit
      vim.keymap.set("n", "<leader>qd", function()
        require("persistence").stop()
      end)
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
    "yetone/avante.nvim",
    event = "VeryLazy",
    lazy = false,
    version = false, -- set this if you want to always pull the latest change
    opts = {
      -- provider = "claude",
      provider = "copilot",
      -- auto_suggestion_provider = "copilot",
      claude = {
        endpoint = "https://api.anthropic.com",
        model = "claude-3-5-sonnet-20241022",
        temperature = 0,
        max_tokens = 4096,
      },
      copilot = {
        model = "gpt-4o-2024-05-13",
        -- model = "gpt-4o-mini",
        max_tokens = 4096,
      },
    },
    -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
    build = "make",
    cond = vim.g.not_in_vscode,
    -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      --- The below dependencies are optional,
      "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
      "zbirenbaum/copilot.lua", -- for providers='copilot'
      {
        -- support for image pasting
        "HakonHarnes/img-clip.nvim",
        event = "VeryLazy",
        opts = {
          -- recommended settings
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
            drag_and_drop = {
              insert_mode = true,
            },
            -- required for Windows users
            use_absolute_path = true,
          },
        },
      },
      {
        -- Make sure to set this up properly if you have lazy=true
        "MeanderingProgrammer/render-markdown.nvim",
        opts = {
          file_types = { "markdown", "Avante" },
        },
        ft = { "markdown", "Avante" },
      },
    },
  },
}
