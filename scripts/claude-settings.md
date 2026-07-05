# claude-settings.sh / claude-mode.sh

`~/.claude/settings.json` を base / local の 2 ファイルに分割管理し、さらに
GLM / Fable / Opus 4.7 の 3 モードをワンコマンドで切替する。

| Path | 役割 | 公開 |
| --- | --- | --- |
| `conf/.claude/settings.base.json` | 共通設定 | コミット |
| `conf/.claude/presets/managed-paths.json` | 切替スクリプトが所有するパス一覧 (whitelist) | コミット |
| `conf/.claude/presets/<mode>.json` | モード別プリセット | コミット |
| `~/.claude/settings.local.json` | マシン固有の値 | マシンローカル |

## 管理パスの真の源泉

`conf/.claude/presets/managed-paths.json` に jq path 配列で列挙する。

- `claude-mode.sh` はこのファイルの各パスを既存 local から削除してから preset を merge する
- `claude-settings.sh` の pull / push は「local に切り出すべきキー」判定にこのファイルを使う
- `.env` の `CLAUDE_EXTRA_LOCAL_KEYS` は「preset に絡まないマシン個別の追加パス」用（例: `enabledPlugins.<plugin>`）。管理パスをここに二重に書く必要はない

preset に新しいキーを増やす場合は `managed-paths.json` にも同じパスを追加する。追加漏れがあると `claude-mode.sh` が起動時にエラーで止まる。

## Commands

| Command                | 用途                                                                 |
| ---------------------- | -------------------------------------------------------------------- |
| `make claude-pull`     | `~/.claude/settings.json` から base.json と local.json を再構築       |
| `make claude-push`     | base.json と local.json をマージして `~/.claude/settings.json` を生成 |
| `make claude-glm`      | GLM5.2 (z.ai) 接続モードに切替                                       |
| `make claude-fable`    | 素の Claude + Fable モードに切替                                     |
| `make claude-opus47`   | 素の Claude + Opus 4.7 (1M) モードに切替                              |

## 秘匿情報

GLM の API トークンは `dotfiles/.env` の `CLAUDE_GLM_AUTH_TOKEN` に置く。
`conf/.claude/presets/glm.json` はプレースホルダ `${CLAUDE_GLM_AUTH_TOKEN}` として持ち、
`claude-mode.sh` 実行時に `envsubst` で埋める。

`.env` は gitignore 前提。トークンをコミットに巻き込まないよう注意。

## 注意

- `~/.claude/settings.local.json` は「管理パスは switcher が所有、その他パスは手編集も可」というハイブリッド運用。管理パス外のキー（`enabledPlugins` の個別値など）は各モード切替後も残る
- `make claude-pull` は `managed-paths.json` を見て切り出すので、GLM モードで pull しても `settings.base.json` に GLM の env が漏れることは無い。ただし新しく preset に追加した env サブキーが `managed-paths.json` に反映されていないと漏れるので、preset 更新時は必ず両方を触ること
