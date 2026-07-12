-- Octo バッファのブラウザプレビュー
--
-- 仕組み:
--   1. octo バッファの内容と _G.octo_buffers[bufnr] のメタデータから
--      shadow バッファ (buftype=nofile, filetype=markdown) を生成
--   2. shadow を非表示の 1x1 floating window に表示（mkdp が cursor 追従に必要）
--   3. shadow バッファに対して MarkdownPreview を起動 → Chrome でプレビュー
--   4. octo の TextChanged で shadow を更新（debounce 300ms）
--   5. octo の CursorMoved で anchor lookup → shadow の cursor 位置を更新（debounce 50ms）

local convert = require("plugins.git.octo.preview.convert")

local M = {}

-- octo_bufnr -> { shadow, win, augroup, convert_timer, cursor_timer, anchors }
M._state = {}

local CONVERT_DEBOUNCE_MS = 300
local CURSOR_DEBOUNCE_MS = 50

local function debounce(existing_timer, ms, fn)
  if existing_timer and not existing_timer:is_closing() then
    existing_timer:stop()
    existing_timer:close()
  end
  local t = vim.uv.new_timer()
  t:start(ms, 0, function()
    t:stop()
    t:close()
    vim.schedule(fn)
  end)
  return t
end

local function get_get_lines(octo_bufnr)
  return function(start_0, end_exclusive_0)
    if not vim.api.nvim_buf_is_valid(octo_bufnr) then
      return {}
    end
    return vim.api.nvim_buf_get_lines(octo_bufnr, start_0, end_exclusive_0, false)
  end
end

local function get_octo_metadata(octo_bufnr)
  if not _G.octo_buffers then
    return nil
  end
  return _G.octo_buffers[octo_bufnr]
end

-- shadow バッファに変換結果を反映
local function refresh_shadow(octo_bufnr)
  local st = M._state[octo_bufnr]
  if not st then
    return
  end
  local meta = get_octo_metadata(octo_bufnr)
  if not meta then
    return
  end

  local md, anchors = convert.build(meta, get_get_lines(octo_bufnr))
  st.anchors = anchors

  if vim.api.nvim_buf_is_valid(st.shadow) then
    vim.bo[st.shadow].modifiable = true
    vim.api.nvim_buf_set_lines(st.shadow, 0, -1, false, md)
    vim.bo[st.shadow].modifiable = false
  end
end

-- octo の cursor 位置に対応する shadow の行を求める
local function map_cursor(anchors, octo_line_1)
  -- 完全一致
  if anchors[octo_line_1] then
    return anchors[octo_line_1]
  end
  -- 直前 anchor に snap
  local best = 1
  for l, m in pairs(anchors) do
    if l <= octo_line_1 and l > best then
      best = l
    end
  end
  return anchors[best] or 1
end

-- Chrome の該当タブに JS を送って data-source-line=N にスクロールさせる。
-- mkdp のフロント側は isActive=true のときのみ scroll する仕様のため、
-- shadow buffer を使う本モジュールでは Chrome を外から直接動かす経路にする。
local function scroll_chrome_to_line(shadow_bufnr, shadow_line)
  local js = string.format(
    [[
    (function(){
      var el = document.querySelector('[data-source-line="' + %d + '"]');
      if (!el) {
        var els = document.querySelectorAll('[data-source-line]');
        var best = null, bestDiff = Infinity;
        for (var i = 0; i < els.length; i++) {
          var n = parseInt(els[i].getAttribute('data-source-line'), 10);
          var d = %d - n;
          if (d >= 0 && d < bestDiff) { best = els[i]; bestDiff = d; }
        }
        el = best;
      }
      if (el) el.scrollIntoView({behavior:'instant', block:'start'});
    })();
  ]],
    shadow_line,
    shadow_line
  )
  -- shadow bufnr の URL を含むタブに JS を送る。
  -- mkdp の preview URL は http://localhost:PORT/{bufnr} 形式（/page/{bufnr}
  -- は SPA 上で /{bufnr} に置き換わる）。末尾 or /page/ の直後で bufnr が
  -- 完全一致するタブだけを対象にする（他 bufnr との誤マッチを回避）
  local suffix_plain = "/" .. shadow_bufnr
  local suffix_page = "/page/" .. shadow_bufnr
  local applescript = string.format(
    [[
tell application "Google Chrome"
  repeat with w in windows
    repeat with t in tabs of w
      set u to URL of t
      if u contains "localhost:" and (u ends with "%s" or u ends with "%s") then
        try
          tell t to execute javascript %s
        end try
      end if
    end repeat
  end repeat
end tell
  ]],
    suffix_plain,
    suffix_page,
    string.format("%q", js)
  )
  vim.uv.spawn("osascript", {
    args = { "-e", applescript },
  }, function() end)
end

local function sync_cursor(octo_bufnr)
  local st = M._state[octo_bufnr]
  if not st or not st.anchors then
    return
  end
  if not vim.api.nvim_buf_is_valid(octo_bufnr) then
    return
  end

  local octo_win = vim.fn.bufwinid(octo_bufnr)
  if octo_win == -1 then
    return
  end
  local cur = vim.api.nvim_win_get_cursor(octo_win)
  local target = map_cursor(st.anchors, cur[1])

  if st.win and vim.api.nvim_win_is_valid(st.win) then
    local last = vim.api.nvim_buf_line_count(st.shadow)
    if target > last then
      target = last
    end
    if target < 1 then
      target = 1
    end
    -- Neovim 側の shadow cursor も一応合わせておく（デバッグ・保険用）
    pcall(vim.api.nvim_win_set_cursor, st.win, { target, 0 })
    -- Chrome を直接 scroll
    scroll_chrome_to_line(st.shadow, target)
  end
end

-- 1x1 の非表示 floating window に shadow を表示
-- noautocmd を有効にすると BufEnter が発火せず mkdp の `command! -buffer` が
-- 登録されないので、noautocmd は false にしておく
local function create_shadow_window(shadow_bufnr)
  return vim.api.nvim_open_win(shadow_bufnr, false, {
    relative = "editor",
    row = 0,
    col = 0,
    width = 1,
    height = 1,
    -- カーソル同期時に nvim_set_current_win で切替できるよう focusable=true
    focusable = true,
    style = "minimal",
    zindex = 1,
  })
end

function M.is_open(octo_bufnr)
  return M._state[octo_bufnr] ~= nil
end

function M.open(octo_bufnr)
  octo_bufnr = octo_bufnr or vim.api.nvim_get_current_buf()
  if M._state[octo_bufnr] then
    vim.notify("OctoPreview: already open for buffer " .. octo_bufnr, vim.log.levels.INFO)
    return
  end
  if vim.bo[octo_bufnr].filetype ~= "octo" then
    vim.notify("OctoPreview: not an octo buffer", vim.log.levels.WARN)
    return
  end
  if not get_octo_metadata(octo_bufnr) then
    vim.notify("OctoPreview: octo metadata not available", vim.log.levels.WARN)
    return
  end

  local shadow = vim.api.nvim_create_buf(false, true)
  vim.bo[shadow].filetype = "markdown"
  vim.bo[shadow].bufhidden = "hide"
  vim.api.nvim_buf_set_name(shadow, string.format("octo-preview://%d.md", octo_bufnr))

  local win = create_shadow_window(shadow)
  local augroup = vim.api.nvim_create_augroup("OctoPreview_" .. octo_bufnr, { clear = true })

  M._state[octo_bufnr] = {
    shadow = shadow,
    win = win,
    augroup = augroup,
    convert_timer = nil,
    cursor_timer = nil,
    anchors = {},
  }

  refresh_shadow(octo_bufnr)

  -- mkdp サーバー起動時に自動発火する open_browser も含めて、
  -- shadow bufnr の URL しか Chrome を開かないよう allowed_bufnr を先に立てる
  vim.g.mkdp_allowed_bufnr = shadow

  -- mkdp の内部 API を直接叩いて server 起動 + open_browser を制御する
  -- MarkdownPreview コマンド経由だと、非同期の起動処理で bufnr が octo に
  -- 戻ってから open_browser が呼ばれ、余計なタブが開いてしまう
  local server_status = vim.fn["mkdp#rpc#get_server_status"]()
  if server_status == -1 then
    vim.fn["mkdp#rpc#start_server"]()
  end

  -- サーバー起動を待って shadow bufnr で open_browser
  local retry_timer = vim.uv.new_timer()
  local attempts = 0
  local function fire_open_browser()
    local st = M._state[octo_bufnr]
    if not st then
      return
    end
    if not vim.api.nvim_win_is_valid(st.win) then
      return
    end
    -- mkdp_browserfunc は許可された shadow bufnr の URL だけ Chrome を開く
    vim.g.mkdp_allowed_bufnr = st.shadow
    -- shadow window の中で open_browser + autocmd 登録を発火する。
    -- mkdp#util#open_browser 経由にすることで shadow buf の CursorMoved 等で
    -- refresh_content が自動発火するようになる（scroll-sync に必要）
    vim.api.nvim_win_call(st.win, function()
      pcall(vim.fn["mkdp#util#open_browser"])
    end)
  end

  if server_status == 1 then
    -- 既に起動済み: 即発火
    fire_open_browser()
  else
    -- repeating timer 内で fire_open_browser を 2 回実行しないよう flag で防ぐ
    local fired = false
    retry_timer:start(300, 300, function()
      attempts = attempts + 1
      vim.schedule(function()
        if fired then
          return
        end
        if vim.g.mkdp_node_channel_id and vim.g.mkdp_node_channel_id ~= 0 then
          fired = true
          if not retry_timer:is_closing() then
            retry_timer:stop()
            retry_timer:close()
          end
          fire_open_browser()
        elseif attempts >= 15 then
          fired = true
          if not retry_timer:is_closing() then
            retry_timer:stop()
            retry_timer:close()
          end
          vim.notify("OctoPreview: mkdp server did not start in time", vim.log.levels.WARN)
        end
      end)
    end)
  end

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = augroup,
    buffer = octo_bufnr,
    callback = function()
      local st = M._state[octo_bufnr]
      if not st then
        return
      end
      st.convert_timer = debounce(st.convert_timer, CONVERT_DEBOUNCE_MS, function()
        if M._state[octo_bufnr] then
          refresh_shadow(octo_bufnr)
        end
      end)
    end,
  })

  vim.api.nvim_create_autocmd("CursorMoved", {
    group = augroup,
    buffer = octo_bufnr,
    callback = function()
      local st = M._state[octo_bufnr]
      if not st then
        return
      end
      st.cursor_timer = debounce(st.cursor_timer, CURSOR_DEBOUNCE_MS, function()
        if M._state[octo_bufnr] then
          sync_cursor(octo_bufnr)
        end
      end)
    end,
  })

  vim.api.nvim_create_autocmd("BufWipeout", {
    group = augroup,
    buffer = octo_bufnr,
    callback = function()
      M.close(octo_bufnr)
    end,
  })

  vim.notify("OctoPreview: opened", vim.log.levels.INFO)
end

function M.close(octo_bufnr)
  octo_bufnr = octo_bufnr or vim.api.nvim_get_current_buf()
  local st = M._state[octo_bufnr]
  if not st then
    return
  end

  if st.convert_timer and not st.convert_timer:is_closing() then
    st.convert_timer:stop()
    st.convert_timer:close()
  end
  if st.cursor_timer and not st.cursor_timer:is_closing() then
    st.cursor_timer:stop()
    st.cursor_timer:close()
  end
  pcall(vim.api.nvim_del_augroup_by_id, st.augroup)

  if st.shadow and vim.api.nvim_buf_is_valid(st.shadow) then
    vim.api.nvim_buf_call(st.shadow, function()
      pcall(vim.cmd, "MarkdownPreviewStop")
    end)
    pcall(vim.api.nvim_buf_delete, st.shadow, { force = true })
  end
  if st.win and vim.api.nvim_win_is_valid(st.win) then
    pcall(vim.api.nvim_win_close, st.win, true)
  end

  M._state[octo_bufnr] = nil
  vim.g.mkdp_allowed_bufnr = 0
  vim.notify("OctoPreview: closed", vim.log.levels.INFO)
end

function M.toggle(octo_bufnr)
  octo_bufnr = octo_bufnr or vim.api.nvim_get_current_buf()
  if M._state[octo_bufnr] then
    M.close(octo_bufnr)
  else
    M.open(octo_bufnr)
  end
end

return M
