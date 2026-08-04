return {
  {
    "potamides/pantran.nvim",
    config = function()
      require("utils").load_env(vim.env.DOTFILES_DIR .. "/.env")
      require("pantran").setup({
        default_engine = "deepl",
        engines = {
          google = {
            fallback = {
              default_source = "en",
              default_target = "ja",
            },
          },
          -- NOTE: must set `DEEPL_AUTH_KEY` env-var
          deepl = {
            default_source = "en",
            default_target = "ja",
            auth_key = vim.fn.getenv("DEEPL_API_KEY"),
          },
        },
        ui = {
          width_percentage = 0.8,
          height_percentage = 0.8,
        },
        window = {
          title_border = { "⭐️ ", " ⭐️    " }, -- for google
          window_config = { border = "rounded" },
        },
        controls = {
          mappings = { -- Help Popup order cannot be changed
            edit = {
              -- normal mode mappings
              n = {
                -- ["j"] = "gj",
                -- ["k"] = "gk",
                ["S"] = require("pantran.ui.actions").switch_languages,
                ["e"] = require("pantran.ui.actions").select_engine,
                ["s"] = require("pantran.ui.actions").select_source,
                ["t"] = require("pantran.ui.actions").select_target,
                ["<C-y>"] = require("pantran.ui.actions").yank_close_translation,
                ["g?"] = require("pantran.ui.actions").help,
                --disable default mappings
                ["<C-Q>"] = false,
                ["gA"] = false,
                ["gS"] = false,
                ["gR"] = false,
                ["ga"] = false,
                ["ge"] = false,
                ["gr"] = false,
                ["gs"] = false,
                ["gt"] = false,
                ["gY"] = false,
                ["gy"] = false,
              },
              -- insert mode mappings
              i = {
                ["<C-y>"] = require("pantran.ui.actions").yank_close_translation,
                ["<C-t>"] = require("pantran.ui.actions").select_target,
                ["<C-s>"] = require("pantran.ui.actions").select_source,
                ["<C-e>"] = require("pantran.ui.actions").select_engine,
                ["<C-S>"] = require("pantran.ui.actions").switch_languages,
              },
            },
            -- Keybindings here are used in the selection window.
            select = {},
          },
        },
      })

      -- DeepL API は 2025年11月に form body 認証を廃止し、Authorization ヘッダー認証を
      -- 要求するようになった。pantran.nvim の deepl エンジンは未対応のため、
      -- pantran.setup 後（config.user 反映済み）に setup をヘッダー認証版へ差し替える。
      -- upstream PR: https://github.com/potamides/pantran.nvim/pull/34
      local deepl = require("pantran.engines.deepl")
      local curl = require("pantran.curl")
      deepl.setup = function()
        if not deepl.config.auth_key then
          error("This engine requires an API key to work!")
        end
        deepl._api = curl.new({
          url = deepl.url_template:format(deepl.config.free_api and "-free" or ""),
          fmt_error = function(response)
            return response.message
          end,
          headers = {
            Authorization = "DeepL-Auth-Key " .. deepl.config.auth_key,
          },
          static_paths = { "languages" },
        })
      end

      -- 翻訳結果をシステムクリップボード(+レジスタ)へコピーするよう上書き
      -- (vim.o.clipboard 未設定のため、既定では無名レジスタにしか入らない)
      local handlers = require("pantran.handlers")
      handlers.yank = function(text)
        vim.fn.setreg("+", text, "u")
      end

      -- Pantran: 翻訳UIを開く
      vim.keymap.set(
        { "n", "v" },
        "<leader>sj",
        ":'<,'>Pantran<CR>",
        { noremap = true, silent = true, desc = "Translate to Japanese (en->ja)" }
      )
      vim.keymap.set(
        { "n", "v" },
        "<leader>se",
        ":'<,'>Pantran source=JA target=EN-US<CR>",
        { noremap = true, silent = true, desc = "Translate to English (ja->en)" }
      )

      -- Pantran: 翻訳結果で置換 (mode=replace)
      vim.keymap.set(
        "n",
        "<leader>srj",
        ":Pantran mode=replace<CR>",
        { noremap = true, silent = true, desc = "Replace to Japanese (en->ja)" }
      )
      vim.keymap.set(
        "v",
        "<leader>srj",
        ":'<,'>Pantran mode=replace<CR>",
        { noremap = true, silent = true, desc = "Replace to Japanese (en->ja)" }
      )
      vim.keymap.set(
        "n",
        "<leader>sre",
        ":Pantran mode=replace source=JA target=EN-US<CR>",
        { noremap = true, silent = true, desc = "Replace to English (ja->en)" }
      )
      vim.keymap.set(
        "v",
        "<leader>sre",
        ":'<,'>Pantran mode=replace source=JA target=EN-US<CR>",
        { noremap = true, silent = true, desc = "Replace to English (ja->en)" }
      )
    end,
  },
}
