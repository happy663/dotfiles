# claude-settings.sh

`~/.claude/settings.json` を base / local の 2 ファイルに分割管理するスクリプト。

| Path | 役割 | 公開 |
| --- | --- | --- |
| `conf/.claude/settings.base.json` | 共通設定 | コミット |
| `~/.claude/settings.local.json` | マシン固有の値 | マシンローカル |

## ローカル扱いするキーの定義

汎用キー（`model` / `effortLevel` / `permissions.defaultMode`）はスクリプト内に
`generic_local_keys` として定数で持つ。それ以外で local 扱いにしたいキーは
`.env` の `CLAUDE_EXTRA_LOCAL_KEYS` に jq path 配列で書く。

```bash
# .env
CLAUDE_EXTRA_LOCAL_KEYS='[
  ["enabledPlugins", "my-plugin"],
  ["extraKnownMarketplaces", "my-marketplace"]
]'
```

## Commands

| Command           | Description                                                          |
| ----------------- | -------------------------------------------------------------------- |
| `make claude-pull` | `~/.claude/settings.json` から base.json と local.json を再構築       |
| `make claude-push` | base.json と local.json をマージして `~/.claude/settings.json` を生成 |

## 注意

`.env` の更新を忘れて `make claude-pull` すると、local 扱いにすべきキーが
`settings.base.json` に流出する。commit 前に必ず
`git diff conf/.claude/settings.base.json` を確認すること
（`make claude-pull` の最後にも diff が自動表示される）。
