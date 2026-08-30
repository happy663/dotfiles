import { execFile } from "node:child_process";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// tmux の window-status / pane-border に pi の状態を出す。
//
// 状態の語彙（正の定義は issue #315。claude / codex 側の実装は
// conf/.config/tmux/scripts/agent-window-status.sh。語彙を変えるときは両方直すこと）:
//   running   作業中
//   blocked   許可・質問で中断している
//   idle      応答が終わって次の指示を待っている
//   error     失敗して終わった
//   （未設定）Agent がいない
//
// pi は agent_end に失敗フラグを持たないため error は出さない。running / blocked /
// idle の3値のみ。permission 系の拡張は tool_call 内で ui.confirm を await する方式で、
// ダイアログが開いたことを知る手段が無いので blocked は質問ツールからのみ検出する。

const PANE = process.env.TMUX_PANE;

// 入力待ちで止まる質問系ツール。pi-ask-user が registerTool する名前は "ask_user"
// （node_modules/pi-ask-user/index.ts:1993）。他の質問系拡張を入れたらここに足す。
const ASK_TOOLS = new Set(["ask_user"]);

function tmux(...args: string[]): void {
  execFile("tmux", args, () => {});
}

// @agent-status-at には最終更新時刻（epoch 秒）を入れる。ピッカー側が
// 「running なのに一定時間更新されていない」を検出するための生存signal。
// シェル版の touch_at と同じ役割。
function touchAt(): void {
  tmux("set-option", "-p", "-t", PANE!, "@agent-status-at", String(Math.floor(Date.now() / 1000)));
}

function clearState(): void {
  tmux("set-option", "-pu", "-t", PANE!, "@agent-status");
  tmux("set-option", "-pu", "-t", PANE!, "@agent-status-at");
}

function setState(state: string): void {
  tmux("set-option", "-p", "-t", PANE!, "@agent-status", state);
  touchAt();
}

export default function (pi: ExtensionAPI) {
  // tmux の外や、ペインを特定できない場合は何もしない。
  if (!process.env.TMUX || !PANE) return;

  // 起動時は idle にしない。idle は「応答が終わって次の指示を待っている」であり、
  // 起動直後はまだ何も応答していない。代わりに、前のセッションが異常終了して
  // 残った古い状態を掃除する。
  pi.on("session_start", async () => clearState());
  pi.on("agent_start", async () => setState("running"));

  pi.on("tool_execution_start", async (event) => {
    if (ASK_TOOLS.has(event.toolName)) setState("blocked");
    else touchAt();
  });

  pi.on("tool_execution_end", async (event) => {
    if (ASK_TOOLS.has(event.toolName)) setState("running");
    else touchAt();
  });

  // agent_end ではなく agent_settled を使う。agent_end の後も pi は自動リトライや
  // compaction、キュー済みメッセージの続行をしうるので、そこで idle にすると早すぎる。
  pi.on("agent_settled", async () => setState("idle"));

  pi.on("session_shutdown", async () => clearState());
}
