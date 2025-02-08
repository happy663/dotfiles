return {
  {
    "sphamba/smear-cursor.nvim",
    config = function()
      local smear_cursor = require("smear_cursor")

      -- Configure smear cursor options
      smear_cursor.setup({
        -- Smear cursor when switching buffers or windows
        smear_between_buffers = true,

        -- Smear cursor when moving within line or to neighbor lines
        smear_between_neighbor_lines = true,

        -- Minimum distances for smearing
        min_horizontal_distance_smear = 0,
        min_vertical_distance_smear = 0,

        -- Smear cursor when entering or leaving command line mode
        smear_to_cmd = true,

        -- Draw the smear in buffer space instead of screen space when scrolling
        scroll_buffer_space = false,

        -- Legacy computing symbols support
        legacy_computing_symbols_support = true,

        -- Cursor and smear settings for different modes
        vertical_bar_cursor = true,
        smear_insert_mode = true,
        vertical_bar_cursor_insert_mode = true,
        smear_replace_mode = true,
        horizontal_bar_cursor_replace_mode = true,

        -- Advanced configuration
        hide_target_hack = true,
        max_kept_windows = 50,
        windows_zindex = 300,
        filetypes_disabled = {},
        time_interval = 17,
        delay_event_to_smear = 1,
        delay_after_key = 1,

        -- Smear animation parameters
        stiffness = 0.6,
        trailing_stiffness = 0.3,
        trailing_exponent = 2,
        slowdown_exponent = 0,
        distance_stop_animating = 0.1,

        -- Insert mode specific parameters
        stiffness_insert_mode = 0.3,
        trailing_stiffness_insert_mode = 0.3,
        trailing_exponent_insert_mode = 1,
        distance_stop_animating_vertical_bar = 0.875,

        -- Rasterization and color parameters
        max_slope_horizontal = 0.5,
        min_slope_vertical = 2,
        color_levels = 16,
        gamma = 2.2,
        max_shade_no_matrix = 0.75,
        matrix_pixel_threshold = 0.7,
        matrix_pixel_threshold_vertical_bar = 0.3,
        matrix_pixel_min_factor = 0.5,
        volume_reduction_exponent = 0.3,
        minimum_volume_factor = 0.7,
        max_length = 25,
        max_length_insert_mode = 1,
      })

      -- terminalやlazygitでアニメーションがあると邪魔に感じたので無効化
      vim.api.nvim_create_autocmd("TermEnter", {
        pattern = { "term://*toggleterm#*", "term://*lazygit*" },
        callback = function()
          smear_cursor.enabled = false
        end,
      })

      -- バッファに入ったら再び有効化
      vim.api.nvim_create_autocmd("BufEnter", {
        callback = function()
          smear_cursor.enabled = true
        end,
      })
    end,
  },
}
