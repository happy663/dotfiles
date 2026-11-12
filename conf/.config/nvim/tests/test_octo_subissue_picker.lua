package.path = vim.fn.getcwd()
  .. "/conf/.config/nvim/lua/?.lua;"
  .. vim.fn.getcwd()
  .. "/conf/.config/nvim/lua/?/init.lua;"
  .. package.path

local function assert_eq(actual, expected, message)
  if not vim.deep_equal(actual, expected) then
    error(string.format("%s: expected %s, got %s", message, vim.inspect(expected), vim.inspect(actual)))
  end
end

local ROOT_URL = "https://github.com/happy663/dotfiles/issues/10"
local CHILD_URL = "https://github.com/happy663/dotfiles/issues/11"

local PARENT_CHAIN_JSON = '{"number":10,"parent":null}'
local TREE_JSON = string.format(
  [[{"number":10,"title":"root","state":"OPEN","stateReason":null,"url":"%s",
     "subIssues":{"nodes":[
       {"number":11,"title":"child","state":"CLOSED","stateReason":"COMPLETED","url":"%s",
        "subIssues":{"nodes":[]}}
     ]}}]],
  ROOT_URL,
  CHILD_URL
)

local copied = {}
local tree_queries = {}
local select_call

package.loaded["octo.utils"] = {
  get_current_buffer = function()
    return {
      repo = "happy663/dotfiles",
      number = 10,
      isIssue = function()
        return true
      end,
    }
  end,
  split_repo = function()
    return "happy663", "dotfiles"
  end,
  icons = {
    issue = {
      open = { "O ", "OctoGreen" },
      closed = { "C ", "OctoPurple" },
      not_planned = { "N ", "OctoGrey" },
    },
  },
  copy_url = function(url)
    table.insert(copied, url)
  end,
  get_issue = function() end,
  info = function() end,
  error = function(msg)
    error(msg)
  end,
}

package.loaded["octo.gh"] = {
  create_callback = function(opts)
    return opts.success
  end,
  api = {
    graphql = function(args)
      if args.query:find("subIssues") then
        table.insert(tree_queries, args.query)
        args.opts.cb(TREE_JSON)
      else
        args.opts.cb(PARENT_CHAIN_JSON)
      end
    end,
  },
}

vim.ui.select = function(items, opts, on_choice)
  select_call = { items = items, opts = opts, on_choice = on_choice }
end

-- Open the picker with the given Octo config and return what was passed to vim.ui.select.
local function open_picker(octo_config)
  package.loaded["octo.config"] = octo_config
  package.loaded["plugins.git.octo.helpers"] = nil
  select_call = nil
  require("plugins.git.octo.helpers").list_subissues_and_jump()
  assert(select_call, "vim.ui.select が呼ばれる")
  return select_call
end

-- Snacks wraps each vim.ui.select item: fields fall through to the original via __index.
local function snacks_item(original, idx)
  return setmetatable({ item = original, idx = idx, text = idx .. " x" }, { __index = original })
end

local function octo_config_with_lhs(lhs)
  return { values = { picker_config = { mappings = { copy_url = { lhs = lhs } } } } }
end

-- 標準の Octo 設定（<C-y>）
local call = open_picker(octo_config_with_lhs("<C-y>"))

local _, url_fields = tree_queries[1]:gsub("%f[%w]url%f[%W]", "")
assert_eq(url_fields, 4, "サブissueツリーのクエリは全4階層で url を取得する")

assert_eq(call.items[1].url, ROOT_URL, "起点issueの item が url を持つ")
assert_eq(call.items[2].url, CHILD_URL, "子issueの item が url を持つ")

local snacks = call.opts.snacks
assert_eq(type(snacks.actions.octo_copy_url), "function", "octo_copy_url アクションが定義される")
assert_eq(
  snacks.win.input.keys["<C-y>"],
  { "octo_copy_url", mode = { "i", "n" } },
  "入力欄の <C-y> (i/n) が octo_copy_url に割り当たる"
)
assert_eq(snacks.win.list.keys["<C-y>"], "octo_copy_url", "リストの <C-y> が octo_copy_url に割り当たる")

snacks.actions.octo_copy_url({}, snacks_item(call.items[1], 1))
snacks.actions.octo_copy_url({}, snacks_item(call.items[2], 2))
assert_eq(copied, { ROOT_URL, CHILD_URL }, "選択中 issue の URL で octo_utils.copy_url を呼ぶ")

copied = {}
snacks.actions.octo_copy_url({}, nil)
assert_eq(copied, {}, "選択行がなければ何もコピーしない")

-- 既存の操作を壊していない
assert_eq(snacks.win.input.keys["<a-,>"], { "octo_widen_root", mode = { "i", "n" } }, "<a-,> の割り当てが残る")
assert_eq(snacks.win.list.keys["<a-.>"], "octo_narrow_root", "<a-.> の割り当てが残る")

-- Octo 側で copy_url のキーを変えたら追従する
call = open_picker(octo_config_with_lhs("<C-u>"))
assert_eq(
  call.opts.snacks.win.input.keys["<C-u>"],
  { "octo_copy_url", mode = { "i", "n" } },
  "Octo の copy_url.lhs に追従する (input)"
)
assert_eq(call.opts.snacks.win.list.keys["<C-u>"], "octo_copy_url", "Octo の copy_url.lhs に追従する (list)")
assert_eq(call.opts.snacks.win.input.keys["<C-y>"], nil, "キー変更時は <C-y> を割り当てない")

-- Octo の設定から取れなければ <C-y> にフォールバックする
call = open_picker({ values = {} })
assert_eq(call.opts.snacks.win.list.keys["<C-y>"], "octo_copy_url", "設定がなければ <C-y> を使う")

print("octo subissue picker tests passed")
