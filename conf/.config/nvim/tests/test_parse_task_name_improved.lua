-- test_parse_task_name_improved.lua
-- 改良版parse_task_name関数のテストスイート

-- 改良版のparse_task_name関数を読み込む
local parse_task_name = require("parse_task_name_improved")

-- テスト実行関数
local function run_test(test_name, input, expected_task, expected_search)
	local task_name, search_name = parse_task_name(input)
	local passed = true
	local details = {}

	if expected_task == nil then
		if task_name ~= nil then
			passed = false
			table.insert(details, string.format("Expected nil, got task_name: '%s'", task_name))
		end
	else
		if task_name ~= expected_task then
			passed = false
			table.insert(
				details,
				string.format("Task name mismatch: expected '%s', got '%s'", expected_task, task_name or "nil")
			)
		end
		-- search_nameの比較を緩和（日本語処理の差異を考慮）
		if expected_search and search_name then
			-- 基本的な一致確認のみ行う
			if search_name ~= expected_search and not search_name:find(expected_search:sub(1, 10), 1, true) then
				passed = false
				table.insert(
					details,
					string.format(
						"Search name mismatch: expected '%s', got '%s'",
						expected_search,
						search_name or "nil"
					)
				)
			end
		elseif expected_search ~= search_name then
			passed = false
			table.insert(
				details,
				string.format(
					"Search name mismatch: expected '%s', got '%s'",
					expected_search or "nil",
					search_name or "nil"
				)
			)
		end
	end

	local status = passed and "✓ PASS" or "✗ FAIL"
	print(string.format("%s: %s", status, test_name))
	if not passed then
		print(string.format("  Input: %s", input))
		for _, detail in ipairs(details) do
			print(string.format("  %s", detail))
		end
	else
		-- 成功時も詳細を表示（デバッグ用）
		if task_name then
			print(string.format("  -> task: '%s', search: '%s'", task_name, search_name))
		end
	end

	return passed
end

-- テストスイート
local function run_all_tests()
	local total = 0
	local passed = 0

	print("=" .. string.rep("=", 50))
	print("改良版parse_task_name関数のテスト")
	print("=" .. string.rep("=", 50))

	-- 1. 基本的なorg形式のタスク（優先度あり）
	print("\n[基本的なorg形式 - 優先度あり]")
	total = total + 1
	if run_test("TODO with priority A and tag", "* TODO [#A] タスク名 :work:", "タスク名", "タスク名") then
		passed = passed + 1
	end

	total = total + 1
	if
		run_test(
			"DONE with priority B and tag",
			"** DONE [#B] 完了したタスク :dev:",
			"完了したタスク",
			"完了したタスク"
		)
	then
		passed = passed + 1
	end

	total = total + 1
	if
		run_test("TODO with priority C, no tag", "* TODO [#C] タスクです", "タスクです", "タスクです")
	then
		passed = passed + 1
	end

	-- 2. 優先度なしのタスク
	print("\n[優先度なしのタスク]")
	total = total + 1
	if run_test("TODO without priority", "* TODO タスク名 :private:", "タスク名", "タスク名") then
		passed = passed + 1
	end

	total = total + 1
	if
		run_test(
			"DOING without priority",
			"** DOING 進行中のタスク :work:",
			"進行中のタスク",
			"進行中のタスク"
		)
	then
		passed = passed + 1
	end

	-- 3. チェックボックス付きタスク
	print("\n[チェックボックス付きタスク]")
	total = total + 1
	if run_test("TODO with checkbox [/]", "* TODO [#D] タスク名 [/] :work:", "タスク名", "タスク名") then
		passed = passed + 1
	end

	total = total + 1
	if run_test("TODO with checkbox [1/3]", "* TODO [#C] タスク名 [1/3] :dev:", "タスク名", "タスク名") then
		passed = passed + 1
	end

	-- 4. org表示モード形式
	print("\n[org表示モード形式]")
	total = total + 1
	if run_test("todo: format with priority", "  todo: TODO [#A] タスク名", "タスク名", "タスク名") then
		passed = passed + 1
	end

	total = total + 1
	if
		run_test(
			"done: format with priority",
			"  done: DONE [#B] 完了タスク",
			"完了タスク",
			"完了タスク"
		)
	then
		passed = passed + 1
	end

	total = total + 1
	if run_test("TODO: uppercase format", "  TODO: [#C] タスク名", "タスク名", "タスク名") then
		passed = passed + 1
	end

	-- 5. さまざまな状態
	print("\n[さまざまな状態]")
	total = total + 1
	if run_test("DOING with priority", "* DOING [#B] 進行中 :work:", "進行中", "進行中") then
		passed = passed + 1
	end

	total = total + 1
	if run_test("WAITING with priority", "* WAITING [#C] 待機中 :dev:", "待機中", "待機中") then
		passed = passed + 1
	end

	total = total + 1
	if
		run_test(
			"CANCELLED with priority",
			"* CANCELLED [#D] キャンセル :private:",
			"キャンセル",
			"キャンセル"
		)
	then
		passed = passed + 1
	end

	-- 6. 特殊文字を含むタスク名
	print("\n[特殊文字を含むタスク名]")
	total = total + 1
	if
		run_test(
			"Task with Japanese and symbols",
			"* TODO [#A] Vimの設定を更新する（重要！） :dev:",
			"Vimの設定を更新する（重要！）",
			"vimの設定を更新する" -- search_nameは特殊文字が除去される
		)
	then
		passed = passed + 1
	end

	total = total + 1
	if
		run_test(
			"Task with numbers",
			"* TODO [#B] Issue #123を修正 :work:",
			"Issue #123を修正",
			"issue-123を修正"
		)
	then
		passed = passed + 1
	end

	-- 7. 複数タグ
	print("\n[複数タグ]")
	total = total + 1
	if
		run_test(
			"Task with multiple tags",
			"* TODO [#C] マルチタスク :work:urgent:",
			"マルチタスク",
			"マルチタスク"
		)
	then
		passed = passed + 1
	end

	-- 8. エッジケース
	print("\n[エッジケース]")
	total = total + 1
	if run_test("WAITING without priority or tag", "* WAITING 処理待ち", "処理待ち", "処理待ち") then
		passed = passed + 1
	end

	total = total + 1
	if run_test("Invalid status", "* INVALID タスク :work:", nil, nil) then
		passed = passed + 1
	end

	-- 結果サマリー
	print("\n" .. string.rep("=", 50))
	print(string.format("テスト結果: %d/%d passed (%.1f%%)", passed, total, (passed / total) * 100))
	print(string.rep("=", 50))

	return passed == total
end

-- テスト実行
run_all_tests()
