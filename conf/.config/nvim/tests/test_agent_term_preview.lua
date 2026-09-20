-- ピッカーのプレビュー（issue #318）のテスト。
-- tmux と相手 nvim には触れず、preview.fetch を関数境界で差し替えて
-- send_to 側の表示・凍結・失敗処理だけを検証する。
--
--   cd <repo root>
--   nvim --headless -l conf/.config/nvim/tests/test_agent_term_preview.lua
-- このリポジトリの設定は $HOME 配下へ symlink されるため、Neovim の runtimepath には
-- ~/.config/nvim（= main のコピー）が入っている。worktree でテストを走らせると
-- そちらが先に解決されて main のコードをテストしてしまうので、worktree を先頭に置く。
vim.opt.runtimepath:prepend(vim.fn.getcwd() .. "/conf/.config/nvim")

package.path = vim.fn.getcwd()
  .. "/conf/.config/nvim/lua/?.lua;"
  .. vim.fn.getcwd()
  .. "/conf/.config/nvim/lua/?/init.lua;"
  .. package.path

-- プレビューが出る幅を用意する（既定の 80 桁だと 1 カラムへフォールバックする）。
vim.o.columns = 194
vim.o.lines = 45

-- デバウンスと自動更新を 0 にして、タイマーに依存せず同期的に取得させる。
-- （send_to は refresh_interval_ms を読み込み時に固定するので、require より前に設定する）
local config = require("agent_term.config")
config.send_to.preview.debounce_ms = 0
config.send_to.refresh_interval_ms = 0

local tests = {}
local function test(display, fn)
  tests[#tests + 1] = { display = display, fn = fn }
end

local function assert_eq(actual, expected, message)
  if actual ~= expected then
    error(string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
  end
end

local function assert_true(value, message)
  if not value then
    error(message .. ": expected truthy, got " .. tostring(value))
  end
end

local function assert_false(value, message)
  if value then
    error(message .. ": expected falsy, got " .. tostring(value))
  end
end

local function pane(id, status)
  return {
    pane_id = id,
    status = status or "running",
    stale = false,
    task = "#task-" .. id,
    project = "dotfiles",
    session = "test",
    window_index = tonumber((id:gsub("%D", ""))) or 1,
    pane_index = 0,
    path = "/home/happy/src/github.com/happy663/dotfiles",
    nvim_server = "",
    command = "claude",
  }
end

-- panes.list の戻り値。テストごとに差し替える。
local current_panes = { pane("1"), pane("2", "blocked"), pane("3", "idle") }
package.loaded["agent_term.picker.panes"] = {
  list = function()
    return vim.deepcopy(current_panes)
  end,
  exists = function()
    return true
  end,
}

-- preview.fetch の戻り値をテストから制御する。
local fetch_calls = 0
local next_lines = nil
local next_error = nil
local function reset_fetch(lines, err)
  fetch_calls = 0
  next_lines = lines
  next_error = err
end
package.loaded["agent_term.picker.preview"] = {
  fetch = function()
    fetch_calls = fetch_calls + 1
    if next_error then
      return nil, next_error
    end
    return next_lines, nil
  end,
}

package.loaded["agent_term.draft_buf"] = {
  create_input_buffer = function(name)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(buf, name)
    return buf
  end,
  apply_send_keymaps = function() end,
  read_content = function()
    return ""
  end,
  clear = function() end,
}

package.loaded["agent_term.picker.remote_send"] = {
  send = function()
    return true, "sent"
  end,
}

local send_to = require("agent_term.picker.send_to")

-- プレビューの実装（preview.lua）は package.loaded で差し替えているので、
-- 本物を検証したいテストではファイルから直接読み込む。
local function load_real_preview()
  local path = vim.fn.getcwd() .. "/conf/.config/nvim/lua/agent_term/picker/preview.lua"
  local chunk = assert(loadfile(path))
  return chunk()
end

local function big_lines(count)
  local lines = {}
  for i = 1, count do
    lines[i] = "line " .. i
  end
  return lines
end

local function state()
  local s = send_to.preview_state()
  assert_true(s ~= nil, "picker is open")
  return s
end

local function preview_title()
  local s = state()
  assert_true(s.window ~= nil, "preview window exists")
  local title = vim.api.nvim_win_get_config(s.window).title
  -- title は文字列か [text, hl] のリストで返る。リストなら連結する。
  if type(title) == "table" then
    local parts = {}
    for _, chunk in ipairs(title) do
      parts[#parts + 1] = type(chunk) == "table" and chunk[1] or tostring(chunk)
    end
    return table.concat(parts, "")
  end
  return title
end

local function reopen(lines, err, panes)
  send_to.close()
  if panes then
    current_panes = panes
  end
  reset_fetch(lines, err)
  local ok = send_to.open()
  assert_eq(ok, true, "open")
end

-- 取得と表示 --------------------------------------------------------------

test("open 直後にプレビューを取得する", function()
  reopen({ "a", "b" })
  assert_eq(fetch_calls, 1, "取得回数")
  assert_true(state().visible, "プレビューが表示されている")
end)

test("取得した行がプレビューバッファに表示される", function()
  local s = state()
  local actual = table.concat(vim.api.nvim_buf_get_lines(s.buffer, 0, -1, false), "|")
  assert_eq(actual, "a|b", "バッファ内容")
  assert_eq(table.concat(s.lines, "|"), "a|b", "保持している内容")
end)

test("行末の空白がトリムされる", function()
  local real_preview = load_real_preview()
  local saved = vim.system
  vim.system = function()
    return {
      wait = function()
        return { code = 0, stdout = "a   \nb  \n", stderr = "" }
      end,
    }
  end

  local ok, fetched, ferr = pcall(function()
    return real_preview.fetch({ pane_id = "%1" }, { history_lines = 10 })
  end)
  vim.system = saved

  assert_true(ok, "fetch が例外を出さない: " .. tostring(fetched))
  assert_eq(ferr, nil, "エラーなし")
  assert_eq(table.concat(fetched, "|"), "a|b", "トリム結果")
end)

test("capture-pane の失敗は理由を返す", function()
  local real_preview = load_real_preview()
  local saved = vim.system
  vim.system = function()
    return {
      wait = function()
        return { code = 1, stdout = "", stderr = "can't find pane: %999\n" }
      end,
    }
  end

  local ok, fetched, ferr = pcall(function()
    return real_preview.fetch({ pane_id = "%999" }, { history_lines = 10 })
  end)
  vim.system = saved

  assert_true(ok, "fetch が例外を出さない: " .. tostring(fetched))
  assert_eq(fetched, nil, "行は返らない")
  assert_true(tostring(ferr):find("capture%-pane failed") ~= nil, "理由: " .. tostring(ferr))
end)

-- 失敗と空 ----------------------------------------------------------------

test("1 回の取得失敗では前回の内容を保持する", function()
  reopen({ "good" })
  reset_fetch(nil, "timeout")
  send_to.refresh()
  assert_eq(table.concat(state().lines, "|"), "good", "前回の内容のまま")
  assert_eq(state().failures, 1, "失敗回数")
end)

test("1 回の取得失敗では警告を出さない", function()
  assert_eq(preview_title(), " Preview ", "タイトルは通常のまま")
end)

test("2 回連続の失敗で理由を表示する", function()
  send_to.refresh()
  local lines = table.concat(state().lines, "|")
  assert_true(lines:find("プレビューを取得できない") ~= nil, "理由: " .. lines)
  assert_eq(state().failures, 2, "失敗回数")
end)

test("2 回連続の失敗でタイトルに印を出す", function()
  assert_eq(preview_title(), " Preview (!) ", "タイトル")
end)

test("複数行のエラーでも描画が死なない", function()
  reopen({ "good" })
  reset_fetch(nil, "1行目\n2行目")
  -- force なので 1 回目でも理由を出す
  send_to.refresh_preview()
  local lines = vim.api.nvim_buf_get_lines(state().buffer, 0, -1, false)
  assert_eq(
    table.concat(lines, "|"),
    "プレビューを取得できない:|1行目|2行目",
    "複数行に分解して表示"
  )
  assert_eq(state().failures, 1, "失敗回数")
end)

test("取得が例外を投げても固まらない", function()
  reopen({ "good" })
  local preview_module = package.loaded["agent_term.picker.preview"]
  local saved = preview_module.fetch
  preview_module.fetch = function()
    error("boom")
  end

  local ok, err = send_to.refresh_preview()
  preview_module.fetch = saved

  assert_eq(ok, false, "失敗として返る")
  assert_true(tostring(err):find("boom", 1, true) ~= nil, "理由: " .. tostring(err))

  -- 例外のあとも通常どおり動く（コールバックが壊れていない）
  reset_fetch({ "after" })
  send_to.refresh_preview()
  assert_eq(table.concat(state().lines, "|"), "after", "復帰する")
end)

test("取得した行に改行が混ざっていても行に分解する", function()
  reopen({ "a\nb", "c" })
  local lines = vim.api.nvim_buf_get_lines(state().buffer, 0, -1, false)
  assert_eq(table.concat(lines, "|"), "a|b|c", "行に分解")
end)

test("capture-pane の複数行エラーは1行に畳む", function()
  local real_preview = load_real_preview()
  local saved = vim.system
  vim.system = function()
    return {
      wait = function()
        return { code = 1, stdout = "", stderr = "line one\nline two\n" }
      end,
    }
  end

  local ok, fetched, ferr = pcall(function()
    return real_preview.fetch({ pane_id = "%1" }, { history_lines = 5 })
  end)
  vim.system = saved

  assert_true(ok, "例外なし")
  assert_eq(fetched, nil, "行は返らない")
  assert_eq(ferr:find("\n", 1, true) == nil, true, "改行なし: " .. tostring(ferr))
  assert_true(ferr:find("line one line two", 1, true) ~= nil, "内容: " .. tostring(ferr))
end)

test("取得できたが 0 行なら「出力なし」と出す", function()
  reopen({})
  assert_eq(table.concat(state().lines, "|"), "出力なし", "内容")
  assert_eq(preview_title(), " Preview ", "タイトルは通常に戻る")
end)

test("選択中のペインが消えたらエラーを出さず選択が移る", function()
  reopen({ "p1" }, nil, { pane("1"), pane("2", "blocked") })
  send_to.select_next()
  assert_eq(state().pane_id, "2", "宛先が 2 に移る")

  current_panes = { pane("1") }
  send_to.refresh()
  local s = state()
  assert_eq(s.pane_id, "1", "残ったペインへ移る")
  assert_false(
    table.concat(s.lines, "|"):find("プレビューを取得できない") ~= nil,
    "エラーを出さない"
  )
end)

-- 凍結と復帰（P1） -------------------------------------------------------

test("追従中は refresh で取得する", function()
  reopen(big_lines(200))
  assert_eq(fetch_calls, 1, "open で取得")
  reset_fetch(big_lines(200))
  send_to.refresh()
  assert_eq(fetch_calls, 1, "refresh で取得")
end)

test("上スクロールで paused になる", function()
  assert_false(state().paused, "最初は追従中")
  send_to.preview_scroll_up()
  assert_true(state().paused, "上スクロールで凍結")
  assert_eq(preview_title(), " Preview (paused) ", "タイトル")
end)

test("paused 中は refresh しても取得しない", function()
  local before = table.concat(state().lines, "|")
  reset_fetch({ "changed" })
  send_to.refresh()
  assert_eq(fetch_calls, 0, "取得しない")
  assert_eq(table.concat(state().lines, "|"), before, "内容も変わらない")
end)

test("最下部へ戻すと追従を再開する", function()
  reset_fetch(big_lines(200))
  send_to.preview_scroll_down()
  assert_false(state().paused, "最下部で解除")
  assert_eq(fetch_calls, 1, "解除時に取得")
  assert_eq(preview_title(), " Preview ", "タイトル")
end)

test("G で最下部へ戻して追従を再開する", function()
  send_to.preview_scroll_up()
  assert_true(state().paused, "凍結")
  reset_fetch(big_lines(200))
  send_to.preview_follow()
  assert_false(state().paused, "解除")
  assert_eq(fetch_calls, 1, "取得")
end)

test("paused 中でも宛先変更なら取得する", function()
  reopen(big_lines(200), nil, { pane("1"), pane("2", "blocked") })
  send_to.preview_scroll_up()
  assert_true(state().paused, "凍結")

  reset_fetch({ "p2" })
  send_to.select_next()
  assert_eq(fetch_calls, 1, "宛先変更で取得")
  assert_false(state().paused, "宛先が変わったら追従に戻る")
  assert_eq(state().pane_id, "2", "宛先")
end)

send_to.close()

for _, t in ipairs(tests) do
  local ok, err = pcall(t.fn)
  if not ok then
    error(string.format("FAILED [%s]\n%s", t.display, err))
  end
  print("ok - " .. t.display)
end
print("agent_term preview tests passed")
