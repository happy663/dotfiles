-- test_get_next_task_id.lua
-- get_next_task_id関数のテストスイート

-- モック環境のセットアップ
local test_dir = "/tmp/test_task_logs/"
local original_glob = vim.fn.glob
local original_expand = vim.fn.expand

-- テスト用のモック関数
local function mock_glob(pattern, nosuf, list)
  return _G.mock_files or {}
end

local function mock_expand(path)
  if path:match("^~/") then
    return test_dir
  end
  return path
end

-- テスト実行関数
local function run_test(test_name, mock_files_data, expected_result)
  -- モックファイルリストを設定
  _G.mock_files = mock_files_data

  -- vim.fn関数をモック化
  vim.fn.glob = mock_glob
  vim.fn.expand = mock_expand

  -- 関数を読み込んで実行
  local get_next_task_id_module = require("utils.get_next_task_id")
  local result = get_next_task_id_module.get_next_task_id(test_dir)

  -- 結果を検証
  local passed = result == expected_result
  local status = passed and "✓ PASS" or "✗ FAIL"

  print(string.format("%s: %s", status, test_name))
  if not passed then
    print(string.format("  Expected: %s", expected_result))
    print(string.format("  Got: %s", result))
    print(string.format("  Mock files: %s", vim.inspect(mock_files_data)))
  else
    print(string.format("  Result: %s", result))
  end

  -- クリーンアップ
  _G.mock_files = nil

  return passed
end

-- テストスイート
local function run_all_tests()
  local total = 0
  local passed = 0

  print("=" .. string.rep("=", 50))
  print("get_next_task_id関数のテスト")
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

  -- 結果サマリー
  print("\n" .. string.rep("=", 50))
  print(string.format("テスト結果: %d/%d passed (%.1f%%)", passed, total, (passed / total) * 100))
  print(string.rep("=", 50))

  -- vim.fn関数を元に戻す
  vim.fn.glob = original_glob
  vim.fn.expand = original_expand

  return passed == total
end

-- テスト実行
run_all_tests()
