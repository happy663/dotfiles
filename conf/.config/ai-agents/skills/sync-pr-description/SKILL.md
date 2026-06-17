---
name: sync-pr-description
description: PR descriptionと最新のコード差分を比較し、メソッド名・テスト件数・シグネチャ・検証ケースなど「事実」に基づく記述のズレを検出して同期する。リファクタや review 対応で description が陳腐化したときに使用。「PR description を同期」「PR の本文を最新コードに合わせて」「ディスクリプション差分発生時に同期」「sync PR description」等のリクエストで起動する。
argument-hint: "[<pr-number-or-url>]"
allowed-tools: Bash, Read, Edit, Grep, Glob
disable-model-invocation: false
---

# PR Description 同期スキル

PR description と最新のコード差分を突き合わせ、追加コミット (review 対応、refactor、テスト削除、メソッドリネーム等) で陳腐化した記述を検出し、現状に合わせて修正する。PR 作成時には正確だった description が後から事実とズレるのを防ぐ。

## トリガー

以下のいずれかの言い回しで起動する:

* 「PR description を同期して」
* 「PR の本文を最新コードに合わせて」
* 「PR description ずれてない？」
* 「ディスクリプション (差分発生時) を同期」
* 「sync PR description」

## 手順

### 1. 対象 PR の特定

* 引数で PR 番号 or URL が渡されている場合 → それを使用
* 引数なしの場合:
    * 現在のブランチから検索: `gh pr view --json number,headRefName,url`
    * 見つからない → ユーザーに PR 番号を確認する

### 2. PR の情報収集

以下を並列で取得する:

```bash
# PR description をローカルに保存 (Edit ツールで操作するため)
gh pr view <num> --json body --jq .body > /tmp/pr-sync-body.md

# PR のコミット履歴 (description との対応関係を見るため)
gh pr view <num> --json commits --jq '.commits[] | .messageHeadline'

# 変更ファイル一覧
gh pr view <num> --json files --jq '.files[].path'
```

### 3. ドリフト検出

description 内で「事実として書かれた記述」を抽出し、最新のコードと照合する。確認する観点は以下:

#### (a) 識別子 (クラス名・メソッド名・サービス ID)

description 内のバッククォートで囲まれた識別子 (`MethodName`, `ClassName::method`, `service_id` 等) を抽出し、コードベースで存在を確認する。

* 存在しない場合は git log で rename を追跡する
    * `git log --all --oneline -S '<旧識別子>' -- <該当ファイル>` で rename コミットを特定
* 完全削除されている場合は description から削除する

#### (b) テスト件数の数値

description 内に「`X tests`」「`既存A + 新規B`」のような数値があれば、最新のテストファイルでカウントし直す。

```bash
# E2E
docker compose exec ms bash -c "cd admin && php -d memory_limit=-1 vendor/bin/phpunit --testsuite=e2e_tests <path>" | grep -E "OK \([0-9]+ tests|tests, "

# Unit
docker compose exec ms bash -c "cd admin && php -d memory_limit=-1 vendor/bin/phpunit <path>" | grep -E "OK \([0-9]+ tests|tests, "
```

#### (c) メソッドシグネチャ

description が `methodName(?Type $arg = null)` のような署名を含む場合、コードと一字一句照合する。

* 引数の追加・削除
* 型の変更 (`?int` → `?Agent` 等)
* 戻り型の変更

#### (d) 検証ケース・テスト名

description 内で個別のテストに言及している場合 (「ハッピーパス」「不正値で 400」等)、テストファイルから `public function テスト名` を一覧化して照合する。削除されたテスト名が description に残っていれば検出する。

#### (e) 変更ファイル一覧

description で「XXX.php に追加」「XXX.php を変更」と書いているファイルが、実際の `gh pr view --json files` に含まれるか確認する。新規追加・削除されたファイルの言及漏れも検出する。

### 4. ドリフトの提示

検出した不一致をユーザーに番号付きで提示する。各ドリフトは以下を含む:

* description 内の該当行
* description の記述 (現状)
* 実コードの最新状態
* 推定原因 (rename / テスト削除 / シグネチャ変更 等)

例:

```
[D1] L47 メソッド名がリネームされている
     description: `findOwnedAgentIdByAdvertiserId`
     実際:        `findOwnedAgentByAdvertiserId` (commit abc1234 でリネーム)

[D2] L57 テスト件数が古い
     description: OK (19 tests)
     実際:        OK (18 tests) — `存在しないadvertiser_idの場合は400が返ること` が削除されている

[D3] L70 削除されたテストへの言及
     description: 「認可: 存在しない ID、別総代理店配下の ID、論理削除済み ID のいずれも 400」
     実際:        「存在しない ID」のテストは削除済み
```

### 5. 修正方針の確認

ユーザーに「どの修正を適用するか」を確認する。基本は全件適用を推奨する。

判断不能なドリフトがあった場合 (例: description の意図と実装が食い違うがどちらが正か不明) はユーザーに方針を確認する。

### 6. 修正適用

`/tmp/pr-sync-body.md` を Edit ツールで修正する。各ドリフトに対して最小限の置き換えを行う。

修正後、PR に反映:

```bash
gh pr edit <num> --body-file /tmp/pr-sync-body.md
```

### 7. 後処理 (バックスラッシュ混入チェック)

`gh pr edit` 後に念のため body を取り直し、コードブロック内のバッククォートがエスケープされていないかチェックする。

```bash
gh api repos/{owner}/{repo}/issues/comments/... --jq .body | grep '\\`' || echo "OK: no escaped backticks"
```

(コメントではなく PR の場合は `gh api repos/{owner}/{repo}/pulls/<num> --jq .body` で取得する)

### 8. 完了報告

* 修正したドリフトの一覧
* PR URL
* 残ったドリフト (スキップ・要確認のもの) があれば明示

## 注意事項

* description 内の「背景・目的・意図」セクションは事実ベースの記述ではないので、明確な根拠なしに書き換えない。「変更内容」「動作検証」「検証したケース」など事実ベースのセクションのみが本 skill の対象
* 文体は description 内の既存スタイル (常体 or 敬体) を踏襲する
* PR 作成時から長文を引き継いでいるので、全文書き換えではなく該当箇所のみ Edit ツールで置き換える
* description が長く、テスト件数や識別子が複数箇所に散らばっている場合があるので、grep で重複箇所も拾う
* 「やってないこと」セクションは「やってないこと自体が変わった (実は実装された)」場合のみ修正する
* false positive を出すよりも false negative (見落とし) を許容する。判断に迷う場合はユーザーに確認する
* `description: ...` (frontmatter) 内のキーワード「PR description を同期」「PR の本文を最新コードに合わせて」等は本 skill のトリガーになるので、似たフレーズで起動する

## ユースケース例

* PR 作成直後にレビュー対応で refactor → メソッド名や引数が変わった → description にもまだ旧名が残っている
* /code-review や /simplify 等で複数回コード調整 → テスト件数や検証ケース一覧が陳腐化
* レビューコメントの返信内で実装方針を変更 → description の「変更内容」「やってないこと」がズレる
