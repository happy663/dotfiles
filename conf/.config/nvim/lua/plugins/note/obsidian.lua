return {
  {
    "obsidian-nvim/obsidian.nvim",
    cond = vim.g.not_in_vscode,
    version = "*",
    lazy = true,
    ft = "markdown",
    -- Vault 配下のファイルを開いたときにロード
    event = {
      "BufReadPre " .. vim.fn.expand("~") .. "/src/github.com/happy663/notes/**.md",
      "BufNewFile " .. vim.fn.expand("~") .. "/src/github.com/happy663/notes/**.md",
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    opts = {
      workspaces = {
        {
          name = "personal",
          path = "~/src/github.com/happy663/notes",
        },
      },
      completion = {
        nvim_cmp = true,
        min_chars = 2,
      },
      -- 単体ノートは必ず Vault ルートに作る（デイリー編集中でも root に作られる）
      notes_subdir = "",
      new_notes_location = "notes_subdir",
      -- ファイル名はタイトルをslug化したものをそのまま使う（グラフビューでの可読性重視）
      -- リネーム時は :Obsidian rename を使うこと（リンク自動更新のため）
      note_id_func = function(title)
        if title ~= nil then
          -- スペース→ハイフン、英数字・ハイフン・アンダースコア以外は除去
          return title:gsub(" ", "-"):gsub("[^A-Za-z0-9%-_]", ""):lower()
        end
        -- タイトルなしの場合はタイムスタンプでフォールバック
        return os.date("%Y%m%d%H%M%S")
      end,
      daily_notes = {
        folder = "daily",
        date_format = "%Y-%m-%d",
      },
      templates = {
        folder = "templates",
        date_format = "%Y-%m-%d",
        time_format = "%H:%M",
      },
      frontmatter = {
        enabled = true,
      },
      -- Obsidian 標準の [[wikilink]] 記法を採用
      link = {
        style = "wiki",
      },
      attachments = {
        folder = "assets/imgs",
      },
      -- 表示は既存の render-markdown.nvim に任せる（競合回避）
      ui = {
        enable = false,
      },
      -- :ObsidianXxx 形式（旧）ではなく :Obsidian xxx 形式（新）を使う
      legacy_commands = false,
      -- デフォルトマッピング（<CR> の smart_action 等）を無効化
      -- グローバルの <CR> → A<Return><Esc>（core/keymaps.lua）を温存するため
      mappings = {},
    },
    keys = {
      { "<leader>nn", "<cmd>Obsidian new<cr>", desc = "Obsidian: new note" },
      { "<leader>no", "<cmd>Obsidian open<cr>", desc = "Obsidian: open in GUI" },
      { "<leader>nf", "<cmd>Obsidian search<cr>", desc = "Obsidian: search" },
      { "<leader>nt", "<cmd>Obsidian today<cr>", desc = "Obsidian: today's daily" },
      { "<leader>nb", "<cmd>Obsidian backlinks<cr>", desc = "Obsidian: backlinks" },
      { "<leader>np", "<cmd>Obsidian paste_img<cr>", desc = "Obsidian: paste image" },
      { "<leader>nl", "<cmd>Obsidian link<cr>", desc = "Obsidian: insert link", mode = "v" },
    },
    config = function(_, opts)
      require("obsidian").setup(opts)

      -- Vault 内の markdown ファイルでは gf を Obsidian のリンクフォローに上書き
      -- （core/keymaps.lua のグローバル gf が [[wikilink]] を解釈できないため）
      vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
        pattern = vim.fn.expand("~") .. "/src/github.com/happy663/notes/*.md",
        callback = function(ev)
          vim.keymap.set("n", "gf", "<cmd>Obsidian follow_link<cr>", {
            buffer = ev.buf,
            desc = "Obsidian: follow link",
          })
        end,
      })
    end,
  },
}
