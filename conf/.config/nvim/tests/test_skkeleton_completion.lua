package.path = "conf/.config/nvim/lua/?.lua;conf/.config/nvim/lua/?/init.lua;" .. package.path

local completion = require("utils.skkeleton_completion")

local function assert_eq(actual, expected, message)
  if actual ~= expected then
    error(string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
  end
end

assert_eq(completion.profile_for_mode(""), "default", "skkeleton無効時は通常のcmp設定を使う")
assert_eq(completion.profile_for_mode(nil), "default", "モード未設定時は通常のcmp設定を使う")
assert_eq(completion.profile_for_mode("abbrev"), "abbrev", "abbrevではskkeleton補完を使う")
assert_eq(completion.profile_for_mode("hira"), "disabled", "ひらがなモードでは補完を無効化する")
assert_eq(completion.profile_for_mode("kata"), "disabled", "カタカナモードでは補完を無効化する")
assert_eq(
  completion.profile_for_mode("hankata"),
  "disabled",
  "半角カタカナモードでは補完を無効化する"
)
assert_eq(completion.profile_for_mode("zenkaku"), "disabled", "全角英数モードでは補完を無効化する")

local function read_file(path)
  local file = assert(io.open(path, "r"))
  local content = file:read("*a")
  file:close()
  return content
end

local skkeleton_config = read_file("conf/.config/nvim/lua/plugins/japanese/skkeleton.lua")
assert(
  skkeleton_config:find('completionBackend = "nvim%-cmp"'),
  "skkeletonはcmp-skkeletonが登録するnvim-cmp backendを選択する"
)

local cmp_config = read_file("conf/.config/nvim/lua/plugins/completion/cmp.lua")
assert(not cmp_config:find("skkeleton_last_selected", 1, true), "cmp.luaで候補選択を独自追跡しない")
assert(
  not cmp_config:find("register_skkeleton_selection", 1, true),
  "cmp.luaでskkeleton確定処理を再実装しない"
)

local ovim_skkeleton_config = read_file("conf/.config/ovim-nvim/lua/plugins/japanese/skkeleton.lua")
assert(
  ovim_skkeleton_config:find('completionBackend = "nvim%-cmp"'),
  "ovimのskkeletonもnvim-cmp backendを選択する"
)
local ovim_cmp_config = read_file("conf/.config/ovim-nvim/lua/plugins/completion/cmp.lua")
assert(not ovim_cmp_config:find("skkeleton_last_selected", 1, true), "ovimのcmp.luaも候補を独自追跡しない")
assert(
  not ovim_cmp_config:find("register_skkeleton_selection", 1, true),
  "ovimのcmp.luaもskkeleton確定処理を再実装しない"
)

print("skkeleton completion tests passed")
