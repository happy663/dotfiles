return {
  {
    "L3MON4D3/LuaSnip",
    cond = vim.g.not_in_vscode,
    lazy = true,
    event = { "InsertEnter" },
    dependencies = { "rafamadriz/friendly-snippets" },
    config = function()
      local ls = require("luasnip")
      local s = ls.snippet
      local t = ls.text_node
      local i = ls.insert_node
      local c = ls.choice_node

      -- markdown用とOctoバッファ用のスニペットを追加
      ls.add_snippets("markdown", {
        -- 汎用コードブロック
        s("code", {
          t("```"),
          t({ "", "" }),
          i(1, "code here"),
          t({ "", "```" }),
        }),

        -- JavaScript コードブロック
        s("js", {
          t({ "```javascript", "" }),
          i(1, "// JavaScript code here"),
          t({ "", "```" }),
        }),

        -- Python コードブロック
        s("py", {
          t({ "```python", "" }),
          i(1, "# Python code here"),
          t({ "", "```" }),
        }),

        -- Lua コードブロック
        s("lua", {
          t({ "```lua", "" }),
          i(1, "-- Lua code here"),
          t({ "", "```" }),
        }),

        -- Bash コードブロック
        s("bash", {
          t({ "```bash", "" }),
          i(1, "# Bash command here"),
          t({ "", "```" }),
        }),

        -- TypeScript コードブロック
        s("ts", {
          t({ "```typescript", "" }),
          i(1, "// TypeScript code here"),
          t({ "", "```" }),
        }),

        -- JSON コードブロック
        s("json", {
          t({ "```json", "" }),
          i(1, '{"key": "value"}'),
          t({ "", "```" }),
        }),

        -- YAML コードブロック
        s("yaml", {
          t({ "```yaml", "" }),
          i(1, "key: value"),
          t({ "", "```" }),
        }),
      })

      -- Octoバッファ用のスニペットを追加
      ls.add_snippets("octo", {
        -- 汎用コードブロック
        s("code", {
          t("```"),
          t({ "", "" }),
          i(1, "code here"),
          t({ "", "```" }),
        }),

        -- JavaScript コードブロック
        s("js", {
          t({ "```javascript", "" }),
          i(1, "// JavaScript code here"),
          t({ "", "```" }),
        }),

        -- Python コードブロック
        s("py", {
          t({ "```python", "" }),
          i(1, "# Python code here"),
          t({ "", "```" }),
        }),

        -- Lua コードブロック
        s("lua", {
          t({ "```lua", "" }),
          i(1, "-- Lua code here"),
          t({ "", "```" }),
        }),

        -- Bash コードブロック
        s("bash", {
          t({ "```bash", "" }),
          i(1, "# Bash command here"),
          t({ "", "```" }),
        }),

        -- TypeScript コードブロック
        s("ts", {
          t({ "```typescript", "" }),
          i(1, "// TypeScript code here"),
          t({ "", "```" }),
        }),

        -- JSON コードブロック
        s("json", {
          t({ "```json", "" }),
          i(1, '{"key": "value"}'),
          t({ "", "```" }),
        }),

        -- YAML コードブロック
        s("yaml", {
          t({ "```yaml", "" }),
          i(1, "key: value"),
          t({ "", "```" }),
        }),
      })

      -- -- org-mode用のスニペットを追加
      ls.add_snippets("org", {
        -- 開発環境TODO
        s("td", {
          t("* TODO [#"),
          i(1, "C"),
          t("] "),
          i(2, "タスク内容"),
          t(" :"),
          i(3, "dev"),
          t(":"),
        }),

        -- work TODO
        s("tw", {
          t("* TODO [#"),
          i(1, "C"),
          t("] "),
          i(2, "タスク内容"),
          t(" :work:"),
        }),

        -- private TODO
        s("tp", {
          t("* TODO [#"),
          i(1, "C"),
          t("] "),
          i(2, "タスク内容"),
          t(" :private:"),
        }),

        -- 期限付きタスク
        s("tpd", {
          t("* TODO [#"),
          i(1, "C"),
          t("] "),
          i(2, "タスク内容"),
          t(" :"),
          i(3, "private"),
          t(":"),
          t({ "", "   DEADLINE: <" }),
          i(4, "2025-01-20 月"),
          t(">"),
        }),

        -- スケジュール付きタスク
        s("ts", {
          t("* TODO [#"),
          i(1, "C"),
          t("] "),
          i(2, "タスク内容"),
          t(" :"),
          i(3, "private"),
          t(":"),
          t({ "", "   SCHEDULED: <" }),
          i(4, "2025-01-20 月"),
          t(">"),
        }),
      })

      -- friendly-snippetsを読み込み
      require("luasnip.loaders.from_vscode").lazy_load()
    end,
  },
}
