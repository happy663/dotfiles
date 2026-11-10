---
name: disk-cleanup
description: |
  Macのストレージ圧迫の原因を、Nix Store 以外から特定し、削除候補と実行コマンドを提示する。
  「ストレージが足りない」「ディスクが圧迫」「容量を空けたい」「何が容量を食っているか調べて」
  などのリクエストで使用する。
allowed-tools: Bash, Read
disable-model-invocation: true
---

# disk-cleanup

## 手順

1. 計測する（数分かかるので Bash のタイムアウトは10分にする）

   ```bash
   bash ~/.config/ai-agents/skills/disk-cleanup/scripts/disk-report.sh
   ```

2. 大きい順に候補を挙げ、下の表から「コマンド・失うもの」を添えて提示する
3. 削除コマンドは Agent が実行しない。ユーザーが実行する
4. 実行後に `df -h /` の前後差で効果を確かめる

## この環境の落とし穴

* colima のディレクトリは2つある
    * `COLIMA_HOME`（`~/.local/share/colima`）: Docker ソケットがある。丸ごと消すと Docker が止まる
    * `LIMA_HOME`（`~/.colima_lima`）: VM ディスクがある
    * `COLIMA_HOME/_lima` は古い VM の残骸になりうる。レポートの `Stale lima` に出たものだけ消してよい
* VM ディスクはスパースファイル。`ls -l` の見かけのサイズではなく、レポートの actual を見る
* `docker system prune` 後に Mac 側が空いたかは、diffdisk の actual の変化で確かめる
* `docker system prune --volumes` は名前付きボリュームを消さない
* `colima delete -p <name>` は `LIMA_HOME/_disks/colima-<name>` を残す
* `brew cleanup` は不要な依存を autoremove することがある

## 削除コマンド

| 対象 | コマンド | 失うもの |
|---|---|---|
| Docker | `docker system prune -a --volumes` → `colima ssh -- sudo fstrim -av` | 停止中コンテナ、未使用イメージ、匿名ボリューム、ビルドキャッシュ |
| Docker 名前付きボリューム | `docker volume prune -a` | ローカル DB などのデータ |
| 古い lima | `rm -rf <COLIMA_HOME>/_lima` | 古い VM |
| colima プロファイル | `colima delete -p <name>` → `rm -rf <LIMA_HOME>/_disks/colima-<name>` | その VM とデータ |
| npm / uv | `npm cache clean --force` / `uv cache clean` | なし（再ダウンロード） |
| Homebrew | `brew cleanup --prune=all` | キャッシュ、古いバージョン |
