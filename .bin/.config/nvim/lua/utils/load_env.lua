local M = {}

-- Load environment variables from a file
-- @param env_file_path string
-- @return nil
function M.load_env(env_file_path)
  local env_file = vim.fn.expand(env_file_path)

  if vim.fn.filereadable(env_file) == 1 then
    for line in io.lines(env_file) do
      if line:match("^[^#]") then
        local key, value = line:match("([^=]+)=(.+)")
        if key and value then
          -- Remove leading and trailing whitespace
          key = key:gsub("^%s*(.-)%s*$", "%1")
          value = value:gsub("^%s*(.-)%s*$", "%1")
          -- Set environment variables
          vim.fn.setenv(key, value)
        end
      end
    end
  end
end

return M
