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

print("skkeleton completion tests passed")
