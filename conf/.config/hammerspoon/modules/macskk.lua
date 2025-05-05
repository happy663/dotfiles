-- 現在の入力ソースを取得してmacSKKのかな入力か確認する
local function isMacSKKKanaInput()
  local inputSource = hs.keycodes.currentSourceID()
  -- macSKKのかな入力ソースIDを確認して比較
  return inputSource == "org.openlab.skk.kana"
end

-- テスト用にログを出力
hs.hotkey.bind({ "cmd", "alt" }, "I", function()
  if isMacSKKKanaInput() then
    hs.alert.show("macSKK: かな入力中")
  else
    hs.alert.show("macSKK: かな入力ではない")
  end
end)
