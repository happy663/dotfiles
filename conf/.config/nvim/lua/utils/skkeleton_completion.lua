local M = {}

function M.profile_for_mode(mode)
  if mode == nil or mode == "" then
    return "default"
  end

  if mode == "abbrev" then
    return "abbrev"
  end

  return "disabled"
end

return M
