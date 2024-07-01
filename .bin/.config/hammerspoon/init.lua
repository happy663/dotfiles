-- Enable Spotlight search for applications
hs.application.enableSpotlightForNameSearches(true)

-- Function to focus the GhostText window in WezTerm
local function focusWezTermGhostTextWindow()
  local app = hs.application.find("WezTerm")
  if app then
    local window = app:findWindow("GhostText")
    if window then
      window:focus()
      hs.alert.show("Focused GhostText Window")
    else
      local windows = hs.window.allWindows()
      for _, win in ipairs(windows) do
        print(win:title())
      end
    end
  else
    hs.alert.show("WezTerm not found")
  end
end

-- Bind Alt+4 to the focus function
hs.hotkey.bind({ "alt" }, "4", focusWezTermGhostTextWindow)
