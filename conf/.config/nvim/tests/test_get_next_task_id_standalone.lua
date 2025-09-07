-- test_get_next_task_id_standalone.lua
-- get_next_task_id関数のスタンドアロンテスト

-- get_next_task_id関数を直接定義（テスト用）
local function get_next_task_id(logs_dir, mock_files)
  -- テスト時はmock_filesを使用
  local files = mock_files or {}

  local max_id = 0
  for _, file in ipairs(files) do
    local num = tonumber(file:match("task%-(%d+)"))
    if num and num > max_id then
      max_id = num
    end
  end

  return string.format("task-%03d", max_id + 1)
end

-- テスト実行関数
local function run_test(test_name, mock_files_data, expected_result)
  local result = get_next_task_id(nil, mock_files_data)

  local passed = result == expected_result
  local status = passed and "✓ PASS" or "✗ FAIL"

  print(string.format("%s: %s", status, test_name))
  if not passed then
    print(string.format("  Expected: %s", expected_result))
    print(string.format("  Got: %s", result))
    print("  Mock files:")
    for _, file in ipairs(mock_files_data) do
      print("    " .. file)
    end
  else
    print(string.format("  Result: %s", result))
  end

  return passed
end

-- テストスイート
local function run_all_tests()
  local total = 0
  local passed = 0
  local test_dir = "/tmp/test_task_logs/"

  print("=" .. string.rep("=", 50))
  print("get_next_task_id関数のテスト（スタンドアロン版）")
  print("=" .. string.rep("=", 50))

  -- テストケース1: ファイルが存在しない場合
  print("\n[ケース1: ファイルが存在しない]")
  total = total + 1
  if run_test("空のディレクトリ", {}, "task-001") then
    passed = passed + 1
  end

  -- テストケース2: 連番のファイルが存在
  print("\n[ケース2: 連番のファイル]")
  total = total + 1
  if
    run_test("task-001からtask-003まで存在", {
      test_dir .. "task-001-example.org",
      test_dir .. "task-002-another.org",
      test_dir .. "task-003-test.org",
    }, "task-004")
  then
    passed = passed + 1
  end

  -- テストケース3: 歯抜けの番号
  print("\n[ケース3: 歯抜けの番号]")
  total = total + 1
  if
    run_test("task-001, task-003, task-005が存在", {
      test_dir .. "task-001-first.org",
      test_dir .. "task-003-third.org",
      test_dir .. "task-005-fifth.org",
    }, "task-006")
  then
    passed = passed + 1
  end

  -- テストケース4: 大きな番号が存在
  print("\n[ケース4: 大きな番号]")
  total = total + 1
  if
    run_test("task-099が存在", {
      test_dir .. "task-001-first.org",
      test_dir .. "task-099-large.org",
    }, "task-100")
  then
    passed = passed + 1
  end

  -- テストケース5: 3桁を超える番号
  print("\n[ケース5: 3桁を超える番号]")
  total = total + 1
  if run_test("task-999が存在", {
    test_dir .. "task-999-max.org",
  }, "task-1000") then
    passed = passed + 1
  end

  -- テストケース6: 無効なファイル名が混在
  print("\n[ケース6: 無効なファイル名が混在]")
  total = total + 1
  if
    run_test("無効なファイル名と有効なファイル名が混在", {
      test_dir .. "task-001-valid.org",
      test_dir .. "task-abc-invalid.org",
      test_dir .. "not-a-task.org",
      test_dir .. "task-002-valid.org",
      test_dir .. "task-003-valid.org",
    }, "task-004")
  then
    passed = passed + 1
  end

  -- テストケース7: ゼロパディング
  print("\n[ケース7: ゼロパディングの確認]")
  total = total + 1
  if
    run_test("task-009が存在（ゼロパディング確認）", {
      test_dir .. "task-009-test.org",
    }, "task-010")
  then
    passed = passed + 1
  end

  -- テストケース8: 複雑なファイル名
  print("\n[ケース8: 複雑なファイル名]")
  total = total + 1
  if
    run_test("日本語や特殊文字を含むファイル名", {
      test_dir .. "task-001-タスク名.org",
      test_dir .. "task-002-complex-name-with-many-dashes.org",
      test_dir .. "task-003-[special]-chars.org",
    }, "task-004")
  then
    passed = passed + 1
  end

  -- テストケース9: 大きな番号の後の連番
  print("\n[ケース9: 大きな番号の後の連番]")
  total = total + 1
  if run_test("task-100の次", {
    test_dir .. "task-100-hundred.org",
  }, "task-101") then
    passed = passed + 1
  end

  -- テストケース10: ゼロから始まる番号
  print("\n[ケース10: ゼロから始まる番号]")
  total = total + 1
  if run_test("task-000が存在", {
    test_dir .. "task-000-zero.org",
  }, "task-001") then
    passed = passed + 1
  end

  -- 結果サマリー
  print("\n" .. string.rep("=", 50))
  print(string.format("テスト結果: %d/%d passed (%.1f%%)", passed, total, (passed / total) * 100))
  print(string.rep("=", 50))

  return passed == total
end

-- テスト実行
local success = run_all_tests()
os.exit(success and 0 or 1)
