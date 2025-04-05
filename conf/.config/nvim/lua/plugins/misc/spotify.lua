-- /path/to/lazy/plugins/spotify.lua
local function get_device_id()
  local device_id
  local devices = require("spotify.api").call("/me/player/devices").devices
  local active_devices = vim.tbl_filter(function(device)
    return device.is_active
  end, devices)

  if #active_devices > 0 then
    device_id = active_devices[1].id
  elseif #devices > 0 then
    device_id = devices[1].id
  else
    vim.notify("no spotify devices found", vim.log.levels.WARN)
    device_id = nil
  end

  return device_id
end

local function play_produced_by_neputunes_playlist()
  local device_id = get_device_id()
  if not device_id then
    vim.notify("open spotify first!", vim.log.levels.ERROR)
    return
  end

  require("spotify.api").call("/me/player/play?device_id=" .. device_id, "put", {
    context_uri = "spotify:playlist:37i9dQZEVXbbToK0U9fZvp",
  })
  print('playing "Produced by: The Neptunes"')
end

local function handle_spotify_action(action)
  local device_id = get_device_id()
  if not device_id then
    vim.notify("open spotify first!", vim.log.levels.ERROR)
    return
  end

  local endpoints = {
    next = { path = "/me/player/next", method = "post" },
    previous = { path = "/me/player/previous", method = "post" },
    pause = { path = "/me/player/pause", method = "put" },
  }

  local endpoint = endpoints[action]
  if endpoint then
    require("spotify.api").call(endpoint.path .. "?device_id=" .. device_id, endpoint.method)
  end
end

local function next_track()
  handle_spotify_action("next")
end

local function previous_track()
  handle_spotify_action("previous")
end

local function pause()
  handle_spotify_action("pause")
end

return {
  -- "mmuldo/spotify.nvim",
  -- dependencies = {
  --   "nvim-lua/plenary.nvim",
  -- },
  -- config = function()
  --   require("utils").load_env("~/.config/nvim/.env")
  --
  --   require("spotify").setup({
  --     client_id = vim.fn.getenv("SPOTIFY_CLIENT_ID"),
  --     client_secret = vim.fn.getenv("SPOTIFY_CLIENT_SECRET"),
  --   })
  --
  --   vim.keymap.set(
  --     "n",
  --     "<leader>spm",
  --     play_produced_by_neputunes_playlist,
  --     { noremap = true, silent = true, desc = "Play 'Produced by: The Neptunes' playlist" }
  --   )
  --   vim.keymap.set(
  --     "n",
  --     "<leader>spc",
  --     require("spotify.api").currently_playing,
  --     { noremap = true, silent = true, desc = "Currently playing" }
  --   )
  --   vim.keymap.set(
  --     "n",
  --     "<leader>spl",
  --     require("spotify.api").like_current_track,
  --     { noremap = true, silent = true, desc = "Like current track" }
  --   )
  --   vim.keymap.set("n", "<leader>spn", next_track, { noremap = true, silent = true, desc = "Next track" })
  --   vim.keymap.set("n", "<leader>spp", previous_track, { noremap = true, silent = true, desc = "Previous track" })
  --   vim.keymap.set("n", "<leader>spa", pause, { noremap = true, silent = true, desc = "Pause" })
  -- end,
}
