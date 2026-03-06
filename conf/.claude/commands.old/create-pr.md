---
description: "適切な形式でプルリクエストを作成し、Issue連携を行う"
allowed-tools: ["Bash", "Read", "Edit"]
---

# プルリクエスト作成

現在のブランチに対して適切な形式でプルリクエストを作成します。

## 手順:

1. **現在のブランチと変更内容の確認**
   - 現在のブランチがmaster/mainでないことを確認
   - git statusとdiffを確認
   - コミットされていない変更がないかチェック

2. **PRタイトルと本文の生成**
   - 引数でIssue番号が指定された場合：
     - `owner/repo#12345` 形式：他リポジトリのIssue参照
     - `12345` 形式：現在のリポジトリのIssue参照
   - タイトル形式: "Fix/Add/Update: [説明] (fixes #番号)" または "Fix/Add/Update: [説明] (fixes owner/repo#番号)"
   - 引数がない場合はブランチ名に基づいた説明的タイトル
   - PR本文に適切なセクションを含める：
     - 概要 (Overview)
     - 問題 (Problem) - Issue修正の場合
     - やったこと (What was done)
     - 使用方法 (Usage) - 該当する場合
     - テスト (Testing)

3. **PRの作成**
   - `gh pr create`を使用して適切なタイトルと本文でPRを作成
   - Issue参照が指定されている場合は含める
   - 必要に応じて適切なラベルを追加

## 使用方法:
- `/user:create-pr` - 現在のブランチでPRを作成
- `/user:create-pr 12345` - 現在のリポジトリのIssue #12345を修正するPRを作成
- `/user:create-pr owner/repo#12345` - 他のリポジトリのIssue #12345を修正するPRを作成

## Template for PR body:
```
## 概要
[Brief overview of the changes]

## 問題
[Description of the problem being solved - if applicable]

## やったこと
[What was implemented/changed]

## 使用方法
[How to use the new feature - if applicable]

## テスト
[Testing done or required]

🤖 Generated with [Claude Code](https://claude.ai/code)
```