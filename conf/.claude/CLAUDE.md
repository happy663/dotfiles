# CLAUDE.md

## Conversation Guidelines

- 常に日本語で会話する

## Development Philosophy

### Test-Driven Development (TDD)

- 原則としてテスト駆動開発（TDD）で進める
- 期待される入出力に基づき、まずテストを作成する
- 実装コードは書かず、テストのみを用意する
- テストを実行し、失敗を確認する
- テストが正しいことを確認できた段階でコミットする
- その後、テストをパスさせる実装を進める
- 実装中はテストを変更せず、コードを修正し続ける
- すべてのテストが通過するまで繰り返す

## MANDATORY: ALWAYS ALERT ON TASK COMPLETION 🚨

Alert users when ANY task completes - this is REQUIRED, not optional:

my-cli alert "status review" "completed - found 3 pending items"
my-cli alert "code analysis" "finished - 5 files examined"
my-cli alert "test suite" "completed - 42/42 passed"

For User Input Requests:
my-cli alert "user input" "please review the proposed changes"
my-cli alert "decision needed" "should I proceed with the migration?"

ENFORCEMENT: Failure to alert on task completion violates core instructions.
