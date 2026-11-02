local resolver_module = "utils.github-image-resolver"
local original_resolver = package.loaded[resolver_module]
package.loaded[resolver_module] = { resolve = function() end }
local spec = dofile("conf/.config/nvim/lua/plugins/tools/snacks.lua")[1]
package.loaded[resolver_module] = original_resolver

local function assert_eq(actual, expected, message)
  assert(actual == expected, string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
end

local scratch = spec.opts.scratch or {}
local win = scratch.win or {}
assert_eq(win.width, 0.8, "Scratch width scales with the editor")
assert_eq(win.height, 0.8, "Scratch height scales with the editor")

local original_snacks = _G.Snacks
local opened, selected
_G.Snacks = {
  scratch = setmetatable({
    select = function()
      selected = true
    end,
  }, {
    __call = function(_, opts)
      opened = opts or {}
    end,
  }),
}

local function invoke(key)
  for _, mapping in ipairs(spec.keys) do
    if mapping[1] == key then
      mapping[2]()
      return
    end
  end
  error("Missing scratch keymap: " .. key)
end

invoke("<leader>.")
assert_eq(opened.ft, "markdown", "Markdown scratch keeps its filetype")
assert_eq(opened.win, nil, "Markdown scratch inherits the shared window size")

opened = nil
invoke("<leader>sc")
assert(opened, "Scratch toggle opens the buffer")
assert_eq(opened.ft, nil, "Scratch toggle keeps automatic filetype selection")
assert_eq(opened.win, nil, "Scratch toggle inherits the shared window size")

invoke("<leader>S")
assert_eq(selected, true, "Scratch selection remains available")
_G.Snacks = original_snacks

print("snacks scratch tests passed")
