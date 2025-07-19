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

      -- friendly-snippetsを読み込み
      require("luasnip.loaders.from_vscode").lazy_load()
    end,
  },
}
