-- Function to focus the GhostText window in WezTerm
local hs_application = require("hs.application")
local function focusWezTermGhostTextWindow()
  local app = hs_application.find("WezTerm")
  if app then
    local window = app:findWindow("GhostText")
    if window then
      window:focus()
      hs_application.alert.show("Focused GhostText Window")
    else
      local windows = hs_application.window.allWindows()
      for _, win in ipairs(windows) do
        print(win:title())
      end
    end
  else
    hs_application.alert.show("WezTerm not found")
  end
end

-- Bind Alt+4 to the focus function
-- hs_application.hotkey.bind({ "alt" }, "4", focusWezTermGhostTextWindow)
