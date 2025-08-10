-- Enable Spotlight search for applications
hs.application.enableSpotlightForNameSearches(true)

-- ~/.hammerspoon/init.lua
-- dofile(hs.configdir .. "/modules/ghost.lua")
-- dofile(hs.configdir .. "/modules/test.lua")
-- dofile(hs.configdir .. "/modules/google-docs.lua")
-- dofile(hs.configdir .. "/modules/macskk.lua")
dofile(hs.configdir .. "/modules/org-sync.lua")

local log = hs.logger.new("myLogger", "debug")

hs.alert.show("メイン設定ファイルを読み込みました")
