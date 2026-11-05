-- nvim-perf-bench: Neovim の入力遅延を計測するハーネス。
--
-- tmux 内で起動した Neovim から読み込んで使う（Agent のシェルで nvim を直接実行しない）。
--   local P = dofile("<skill>/scripts/bench.lua")
--   P.setup({ out = "<scratchpad>/results.txt" })
--   P.wrap("octo.ui.statuscolumn", "statuscolumn", "statuscol")
--   P.sequence({ { label = "base", keys = P.rep("j", 40), interval = 120 } })
--
-- 計測するもの（1キーあたり）:
--   lat   : キーを送ってから、その後の最初の再描画が終わるまで（ms, p50/p90/max）
--   redraw: そのキーに続く再描画の合計時間（ms）
--   cpu   : 計測区間の CPU 時間 / キー数（ms）。後から走る遅延処理も含む
--   wrap  : P.wrap した関数の呼び出し回数と合計時間 / キー数
-- 計測しないもの: ターミナルが画面へ描く時間。タイマーからの nvim_input は実入力の近似。

local P = _G.NvimPerf or {}
_G.NvimPerf = P

local api = vim.api
local unpack = unpack or table.unpack
local hr = vim.uv.hrtime
local function now()
	return hr() / 1e6
end
P.now = now

P.st = P.st or { active = false, redraws = {} }
P.cnt = P.cnt or {}
P.wrapped = P.wrapped or {}
local st = P.st

---@param opts { out: string }
function P.setup(opts)
	P.out = assert(opts and opts.out, "setup({ out = <results file> }) が必要")
end

local function append(line)
	local f = assert(io.open(assert(P.out, "P.setup() を先に呼ぶ"), "a"))
	f:write(line .. "\n")
	f:close()
end
P.append = append

-- 再描画の開始/終了時刻を記録する
local dp_ns = api.nvim_create_namespace("nvim_perf_bench")
api.nvim_set_decoration_provider(dp_ns, {
	on_start = function()
		if st.active then
			st.rs = now()
		end
	end,
	on_end = function()
		if st.active and st.rs then
			table.insert(st.redraws, { s = st.rs, e = now() })
			st.rs = nil
		end
	end,
})

---モジュールの関数を計時付きの関数で包む（M.fn 経由で呼ばれる関数のみ効く）。
---foldexpr / statuscolumn / foldtext など v:lua.require(...) 経由の関数にも効く。
---@param modname string
---@param fname string
---@param key? string 集計名（省略時は modname.fname）
---@return boolean wrapped
function P.wrap(modname, fname, key)
	key = key or (modname .. "." .. fname)
	local ok, mod = pcall(require, modname)
	if not ok or type(mod) ~= "table" or type(mod[fname]) ~= "function" then
		return false
	end
	if P.wrapped[key] then
		return true
	end
	local orig = mod[fname]
	P.wrapped[key] = { mod = mod, fname = fname, orig = orig }
	mod[fname] = function(...)
		local t = hr()
		local r = { orig(...) }
		local c = P.cnt[key] or { n = 0, ms = 0 }
		c.n = c.n + 1
		c.ms = c.ms + (hr() - t) / 1e6
		P.cnt[key] = c
		return unpack(r)
	end
	return true
end

---P.wrap で包んだ関数を元に戻す
function P.unwrap_all()
	for _, w in pairs(P.wrapped) do
		w.mod[w.fname] = w.orig
	end
	P.wrapped = {}
end

local function pct(t, p)
	if #t == 0 then
		return 0
	end
	local s = vim.deepcopy(t)
	table.sort(s)
	return s[math.max(1, math.min(#s, math.ceil(p * #s)))]
end

local function cpu_ms()
	local r = vim.uv.getrusage()
	return (r.utime.sec + r.stime.sec) * 1000 + (r.utime.usec + r.stime.usec) / 1000
end

---キー列を一定間隔で送り、結果を P.out に1行追記する。
---@param step { label: string, keys: string[], interval?: integer, tail?: integer, measure?: fun(i: integer, key: string): boolean }
---@param done? fun(res: table)
function P.run(step, done)
	local keys = step.keys
	local interval = step.interval or 120
	local tail = step.tail or 600
	local measure = step.measure or function()
		return true
	end
	st.redraws, st.active, P.cnt = {}, true, {}
	local items, i, cpu0, t0 = {}, 0, cpu_ms(), now()
	local timer = assert(vim.uv.new_timer())
	-- fast context から nvim_input する（実際のキー入力が届く状況に近い）
	timer:start(0, interval, function()
		i = i + 1
		if i <= #keys then
			table.insert(items, { ti = now(), measure = measure(i, keys[i]) })
			api.nvim_input(keys[i])
			return
		end
		if i <= #keys + math.ceil(tail / interval) then
			return
		end
		timer:stop()
		timer:close()
		vim.schedule(function()
			st.active = false
			local cpu, wall = cpu_ms() - cpu0, now() - t0
			local lat, rd_n, rd_ms, nm = {}, 0, 0, 0
			for k, it in ipairs(items) do
				local nxt = items[k + 1] and items[k + 1].ti or math.huge
				local first
				for _, r in ipairs(st.redraws) do
					if r.s >= it.ti and r.s < nxt then
						first = first or r.e
						if it.measure then
							rd_n = rd_n + 1
							rd_ms = rd_ms + (r.e - r.s)
						end
					end
				end
				if it.measure then
					nm = nm + 1
					if first then
						table.insert(lat, first - it.ti)
					end
				end
			end
			local res = {
				label = step.label,
				n = nm,
				lat_p50 = pct(lat, 0.5),
				lat_p90 = pct(lat, 0.9),
				lat_max = pct(lat, 1),
				redraws_per_key = rd_n / math.max(1, nm),
				redraw_ms_per_key = rd_ms / math.max(1, nm),
				cpu_ms_per_key = cpu / #keys,
				wall_ms = wall,
				cnt = vim.deepcopy(P.cnt),
			}
			local line = string.format(
				"%-32s n=%3d lat p50=%6.1f p90=%6.1f max=%6.1f | redraw/key=%4.1f %6.2fms | cpu/key=%7.2fms",
				res.label,
				res.n,
				res.lat_p50,
				res.lat_p90,
				res.lat_max,
				res.redraws_per_key,
				res.redraw_ms_per_key,
				res.cpu_ms_per_key
			)
			local extra = {}
			for k, c in pairs(res.cnt) do
				table.insert(extra, string.format("%s %.0f calls/key %.2fms/key", k, c.n / #keys, c.ms / #keys))
			end
			table.sort(extra)
			if #extra > 0 then
				line = line .. " | " .. table.concat(extra, ", ")
			end
			append(line)
			if done then
				done(res)
			end
		end)
	end)
end

---複数ステップを順に実行し、最後に "__SEQ_DONE__" を追記する。
---各ステップは P.run の引数に加えて setup / teardown（関数）を持てる。
---@param steps table[]
---@param done? fun()
function P.sequence(steps, done)
	local idx = 0
	local function nextstep()
		idx = idx + 1
		local s = steps[idx]
		if not s then
			append("__SEQ_DONE__")
			if done then
				done()
			end
			return
		end
		if s.setup then
			s.setup()
		end
		vim.defer_fn(function()
			P.run(s, function()
				if s.teardown then
					s.teardown()
				end
				vim.defer_fn(nextstep, 400)
			end)
		end, 400)
	end
	nextstep()
end

---LuaJIT プロファイラ（jit.p）を開始/停止する。sequence の setup/teardown で使う。
---@param file string 出力先
function P.profile_start(file)
	require("jit.p").start("Fm1i1", file)
end
function P.profile_stop()
	require("jit.p").stop()
end

---2つの実装の出力を入力ごとに比べる（差し替え前後で見た目が変わらないかの確認用）。
---@param a function
---@param b function
---@param inputs table[] 各要素は引数の配列
---@return integer mismatches, string[] samples
function P.compare(a, b, inputs)
	local mism, samples = 0, {}
	for _, args in ipairs(inputs) do
		local ra, rb = vim.inspect({ a(unpack(args)) }), vim.inspect({ b(unpack(args)) })
		if ra ~= rb then
			mism = mism + 1
			if #samples < 20 then
				table.insert(samples, ("args=%s a=%s b=%s"):format(vim.inspect(args), ra, rb))
			end
		end
	end
	return mism, samples
end

---関数1回あたりの平均時間（ms）
---@param fn function
---@param iters integer
function P.micro(fn, iters, ...)
	local t = hr()
	for _ = 1, iters do
		fn(...)
	end
	return (hr() - t) / 1e6 / iters
end

-- キー列を作るヘルパー
function P.rep(k, n)
	local t = {}
	for _ = 1, n do
		table.insert(t, k)
	end
	return t
end
function P.concat(...)
	local t = {}
	for _, l in ipairs({ ... }) do
		vim.list_extend(t, l)
	end
	return t
end

---現在バッファで文字列を含む最初の行番号（見つからなければ1）
function P.find_line(pat, buf)
	for l, s in ipairs(api.nvim_buf_get_lines(buf or 0, 0, -1, false)) do
		if s:find(pat, 1, true) then
			return l
		end
	end
	return 1
end

---指定イベントの autocmd を、現在バッファに効くものだけ定義元付きで列挙する
---@param events? string[]
---@return string[]
function P.list_autocmds(events)
	events = events
		or {
			"CursorMoved",
			"CursorMovedI",
			"TextChanged",
			"TextChangedI",
			"TextChangedP",
			"WinScrolled",
			"ModeChanged",
			"CursorHold",
			"CursorHoldI",
			"InsertCharPre",
		}
	local buf, out = api.nvim_get_current_buf(), {}
	for _, ev in ipairs(events) do
		for _, a in ipairs(api.nvim_get_autocmds({ event = ev })) do
			if not a.buflocal or a.buffer == buf then
				local src = a.command and ("cmd:" .. a.command) or ""
				if type(a.callback) == "function" then
					local info = debug.getinfo(a.callback, "S")
					src = info.short_src .. ":" .. info.linedefined
				end
				table.insert(
					out,
					("%s %s %s %s %s"):format(
						ev,
						a.buflocal and "[buf]" or "[glob]",
						a.pattern or "",
						a.group_name or "-",
						src
					)
				)
			end
		end
	end
	return out
end

return P
