---
name: grill-me-list
description: Interview the user about a plan or design by presenting ALL questions at once as a numbered list with recommended answers, instead of one-by-one dialogue. The user replies only to items they disagree with; no reply means the recommendation is accepted. Use when the user wants a plan stress-tested without tiring back-and-forth, or mentions "grill me list" / "一覧でインタビュー" / "まとめて質問".
---

計画・設計について、対話の往復なしで認識合わせを行う。grill-me の一覧提示版。

## 進め方

1. まずコードベースや issue を調査し、調べれば分かる質問は質問にせず事実として潰す。調査で分かった前提は冒頭に簡潔にまとめて共有する。
2. 設計ツリーを分解し、決めるべき論点をすべて洗い出す。
3. 全質問を番号付き一覧で一度に提示する。AskUserQuestion は使わず、テキストで出す。
4. 各質問には必ず以下を付ける:
   * 推奨案とその理由
   * 論点間に依存関係がある場合はその明記（例:「質問5は質問2で terminal 除外を選んだ場合のみ有効」）
5. 一覧の最後に「異論のある項目だけ番号で返信してください。無回答の項目は推奨案で進めます」と明記する。

## 回答を受けたら

* 確定事項リストを更新して提示する。
* ユーザーの回答から新たな論点が派生した場合は、追加質問もまた一覧形式で出す（1問ずつに戻らない）。
* すべて確定したら、合意内容を実装プラン（変更対象ファイル・変更内容・検証方法）としてまとめる。実装に進むのはユーザーの明示的な指示があってから。

## 注意

* 質問は多くても10個程度に絞る。些末な論点（デフォルトで問題ないもの）は質問にせず「推奨どおり進める前提」として確定事項側に書く。
* ユーザーが一部だけ回答した場合、残りは推奨案で合意とみなしてよいが、確定事項リストには「推奨案で確定（無回答）」と出所を明記する。
