package.path = vim.fn.getcwd()
  .. "/conf/.config/nvim/lua/?.lua;"
  .. vim.fn.getcwd()
  .. "/conf/.config/nvim/lua/?/init.lua;"
  .. package.path

local keymaps = require("plugins.git.octo.buffer_keymaps")

local function assert_eq(actual, expected, message)
  if actual ~= expected then
    error(string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
  end
end

assert_eq(
  keymaps.atlas_review_url({ kind = "pull", repo = "happy663/dotfiles", number = 123 }),
  "https://github.com/happy663/dotfiles/pull/123",
  "PRメタデータからAtlas review用URLを生成する"
)
assert_eq(
  keymaps.atlas_review_url({ kind = "issue", repo = "happy663/dotfiles", number = 123 }),
  nil,
  "IssueバッファではAtlas review用URLを生成しない"
)
assert_eq(keymaps.atlas_review_url(nil), nil, "OctoメタデータがなければURLを生成しない")

vim.cmd("enew")
local pull_bufnr = vim.api.nvim_get_current_buf()
_G.octo_buffers = {
  [pull_bufnr] = { kind = "pull", repo = "happy663/dotfiles", number = 123 },
}
keymaps.octo_buffer_keymaps()
local pull_gd = vim.fn.maparg("gd", "n", false, true)
assert_eq(pull_gd.buffer, 1, "PRバッファのgdはbuffer-local")
assert_eq(pull_gd.desc, "Octo: Open PR diff in Atlas", "PRバッファのgdでAtlas差分を開く")

vim.cmd("enew")
local issue_bufnr = vim.api.nvim_get_current_buf()
_G.octo_buffers[issue_bufnr] = { kind = "issue", repo = "happy663/dotfiles", number = 123 }
keymaps.octo_buffer_keymaps()
local issue_gd = vim.fn.maparg("gd", "n", false, true)
assert_eq(issue_gd.buffer, nil, "Issueバッファではgdを上書きしない")

print("octo buffer keymaps tests passed")
