-- Octoバッファのウィンドウだけ GitHub の配色に見せるためのモジュール。
-- github-nvim-theme の palette API から色を取り出して
-- 専用 highlight group を定義し、winhighlight で octo ウィンドウだけに適用する。

local M = {}

local THEME = "github_dark_dimmed"
local NS_PREFIX = "OctoGh"

local function get_palette()
	local ok, palette = pcall(require, "github-theme.palette")
	if not ok then
		return nil
	end
	local pal_ok, pal = pcall(palette.load, THEME)
	if not pal_ok then
		return nil
	end
	return pal
end

local defined = false

local function define_highlights()
	if defined then
		return true
	end
	local p = get_palette()
	if not p then
		return false
	end

	local bg = p.canvas.default
	local bg_subtle = p.canvas.subtle or p.neutral.subtle
	local fg = p.fg.default
	local fg_muted = p.fg.muted
	local fg_subtle = p.fg.subtle
	local border = p.border.default
	local accent = p.accent.fg
	local accent_emphasis = p.accent.emphasis

	local groups = {
		Normal = { bg = bg, fg = fg },
		NormalNC = { bg = bg, fg = fg },
		SignColumn = { bg = bg, fg = fg_subtle },
		LineNr = { bg = bg, fg = fg_subtle },
		CursorLineNr = { bg = bg_subtle, fg = accent, bold = true },
		CursorLine = { bg = bg_subtle },
		EndOfBuffer = { bg = bg, fg = bg },
		WinSeparator = { fg = border, bg = bg },
		VertSplit = { fg = border, bg = bg },
		FoldColumn = { bg = bg, fg = fg_subtle },
		Folded = { bg = bg_subtle, fg = fg_muted },
		Visual = { bg = p.accent.muted },
		Search = { bg = p.attention.muted, fg = fg },
		MatchParen = { fg = accent_emphasis, bold = true },
		StatusLine = { bg = bg_subtle, fg = fg },
		StatusLineNC = { bg = bg, fg = fg_subtle },
	}

	for name, opts in pairs(groups) do
		vim.api.nvim_set_hl(0, NS_PREFIX .. name, opts)
	end

	defined = true
	return true
end

-- octoバッファのウィンドウに winhighlight をセットする
function M.apply_to_window()
	if not define_highlights() then
		return
	end
	-- winhighlight はウィンドウ単位の設定。上書きする前に
	-- このウィンドウの元の値を保存しておき、octo以外を開いたら復元する。
	if not vim.w.octo_winhl_applied then
		vim.w.octo_saved_winhl = vim.wo.winhighlight
		vim.w.octo_winhl_applied = true
	end
	local mappings = {
		"Normal:" .. NS_PREFIX .. "Normal",
		"NormalNC:" .. NS_PREFIX .. "NormalNC",
		"SignColumn:" .. NS_PREFIX .. "SignColumn",
		"LineNr:" .. NS_PREFIX .. "LineNr",
		"CursorLineNr:" .. NS_PREFIX .. "CursorLineNr",
		"CursorLine:" .. NS_PREFIX .. "CursorLine",
		"EndOfBuffer:" .. NS_PREFIX .. "EndOfBuffer",
		"WinSeparator:" .. NS_PREFIX .. "WinSeparator",
		"VertSplit:" .. NS_PREFIX .. "VertSplit",
		"FoldColumn:" .. NS_PREFIX .. "FoldColumn",
		"Folded:" .. NS_PREFIX .. "Folded",
		"Visual:" .. NS_PREFIX .. "Visual",
		"Search:" .. NS_PREFIX .. "Search",
		"MatchParen:" .. NS_PREFIX .. "MatchParen",
		"StatusLine:" .. NS_PREFIX .. "StatusLine",
		"StatusLineNC:" .. NS_PREFIX .. "StatusLineNC",
	}
	vim.opt_local.winhighlight = table.concat(mappings, ",")
end

-- octoバッファ以外を表示したウィンドウは元の winhighlight に戻す
function M.restore_window()
	if vim.w.octo_winhl_applied then
		vim.wo.winhighlight = vim.w.octo_saved_winhl or ""
		vim.w.octo_winhl_applied = nil
		vim.w.octo_saved_winhl = nil
	end
end

-- 親 colorscheme が変わったら再生成できるようにフラグをリセットする
vim.api.nvim_create_autocmd("ColorScheme", {
	callback = function()
		defined = false
	end,
})

return M
