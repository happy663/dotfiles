-- test_parse_task_name.lua
-- parse_task_name関数のテストスイート

-- parse_task_name関数を抽出（テスト用）
local function parse_task_name(line)
  local task_name = nil

  -- org表示モードのパターン
  if line:match("^%s*todo:") or line:match("^%s*done:") then
    task_name = line:match(":%s*%w+%s+%[#[A-C]%]%s+(.-)%s+%[") or line:match(":%s*%w+%s+%[#[A-C]%]%s+(.-)$")
  else
    task_name = line:match("%*+ %w+ %[#[A-C]%] (.-)%s+:") or line:match("%*+ %w+ %[#[A-C]%] (.-)$")
  end

  if not task_name then
    return nil
  end

  -- タスク名をクリーンアップ
  task_name = task_name:gsub("%[.-%]", ""):gsub(":%w+:", ""):gsub("^%s+", ""):gsub("%s+$", "")
  local search_name = task_name:gsub("[^%w%s]", ""):gsub("%s+", "-"):lower():sub(1, 20)

  return task_name, search_name
end

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
    if search_name ~= expected_search then
      passed = false
      table.insert(
        details,
        string.format("Search name mismatch: expected '%s', got '%s'", expected_search, search_name or "nil")
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
  end

  return passed
end

-- テストスイート
local function run_all_tests()
  local total = 0
  local passed = 0

  print("=" .. string.rep("=", 50))
  print("parse_task_name関数のテスト")
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
  if run_test("TODO with priority C, no tag", "* TODO [#C] タスクです", "タスクです", "タスクです") then
    passed = passed + 1
  end

  -- 2. 優先度なしのタスク（現在の実装では失敗するはず）
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
    run_test("done: format with priority", "  done: DONE [#B] 完了タスク", "完了タスク", "完了タスク")
  then
    passed = passed + 1
  end

  total = total + 1
  if
    run_test(
      "TODO: uppercase format",
      "  TODO: [#C] タスク名",
      nil,
      nil -- 現在の実装では失敗
    )
  then
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
      "vimの設定を更新する重要"
    )
  then
    passed = passed + 1
  end

  total = total + 1
  if
    run_test("Task with numbers", "* TODO [#B] Issue #123を修正 :work:", "Issue #123を修正", "issue-123を修正")
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
      "マルチタスク"
    )
  then
    passed = passed + 1
  end

  -- 結果サマリー
  print("\n" .. string.rep("=", 50))
  print(string.format("テスト結果: %d/%d passed (%.1f%%)", passed, total, (passed / total) * 100))
  print(string.rep("=", 50))

  return passed == total
end

-- テスト実行
-- run_all_tests()
