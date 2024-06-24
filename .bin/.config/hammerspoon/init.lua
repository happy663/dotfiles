-- -- Enable Spotlight search for applications
-- hs.application.enableSpotlightForNameSearches(true)
--
-- -- Function to focus the GhostText window in WezTerm
-- local function focusWezTermGhostTextWindow()
--   local app = hs.application.find("WezTerm")
--   if app then
--     local window = app:findWindow("GhostText")
--     if window then
--       window:focus()
--       hs.alert.show("Focused GhostText Window")
--     else
--       -- hs.alert.show("GhostText Window not found")
--
--       -- Show all window titles for debugging
--       -- local windows = app:allWindows()
--       local windows = hs.window.allWindows()
--       print("Windows:")
--       print(windows)
--       for _, win in ipairs(windows) do
--         print("hoge2")
--         print(win:title())
--         print("hoge2")
--       end
--     end
--   else
--     hs.alert.show("WezTerm not found")
--   end
-- end
--
-- -- Bind Alt+4 to the focus function
-- hs.hotkey.bind({ "alt" }, "4", focusWezTermGhostTextWindow)
--

-- Enable Spotlight search for applications
-- hs.application.enableSpotlightForNameSearches(true)
--
-- -- Function to focus the GhostText window in WezTerm
-- local function focusWezTermGhostTextWindow()
--   local app = hs.application.find("WezTerm")
--   if app then
--     local window = app:findWindow("GhostText")
--     if window then
--       window:focus()
--       hs.alert.show("Focused GhostText Window")
--     else
--       -- Show all window titles for debugging
--       local windows = app:allWindows()
--       print("WezTerm Windows:")
--       for _, win in ipairs(windows) do
--         print(win:title())
--         hs.alert.show(win:title())
--       end
--     end
--   else
--     hs.alert.show("WezTerm not found")
--   end
-- end
--
-- -- Bind Alt+4 to the focus function
-- hs.hotkey.bind({ "alt" }, "4", focusWezTermGhostTextWindow)

-- Enable Spotlight search for applications
hs.application.enableSpotlightForNameSearches(true)

-- Function to focus the GhostText window in WezTerm
local function focusWezTermGhostTextWindow()
  local allWindows = hs.window.allWindows()
  local foundWezTermWindow = false

  print("All Windows:")
  for _, win in ipairs(allWindows) do
    print(win:application():name() .. ": " .. win:title())
    if win:application():name() == "WezTerm" then
      foundWezTermWindow = true
      hs.alert.show(win:title())
    end
  end

  if not foundWezTermWindow then
    hs.alert.show("WezTerm window not found")
  end
end

-- Bind Alt+4 to the focus function
hs.hotkey.bind({ "alt" }, "4", focusWezTermGhostTextWindow)
