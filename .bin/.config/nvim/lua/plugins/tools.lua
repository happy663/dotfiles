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
          debug = true, -- Enable debugging
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
          },
        })
      end,
      cmd = "CopilotChatMyCustomPrompt",
      keys = {
        {
          "<leader>ccmc",
        },
        {
          "<leader>ccq",
          function()
            local input = vim.fn.input("Quick Chat: ")
            if input ~= "" then
              require("CopilotChat").ask(input, { selection = require("CopilotChat.select").buffer })
            end
          end,
          desc = "CopilotChat - Quick chat",
        },
        {
          "<leader>cch",
          function()
            local actions = require("CopilotChat.actions")
            require("CopilotChat.integrations.telescope").pick(actions.help_actions())
          end,
          desc = "CopilotChat - Help actions",
        },
        -- Show prompts actions with telescope
        {
          "<leader>ccp",
          function()
            local actions = require("CopilotChat.actions")
            require("CopilotChat.integrations.telescope").pick(actions.prompt_actions())
          end,
          desc = "CopilotChat - Prompt actions",
          mode = {
            "n",
            "v",
          },
        },
      },
      -- See Commands section for default commands if you want to lazy load on them
    },
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
}
