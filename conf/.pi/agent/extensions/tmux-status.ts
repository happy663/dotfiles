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

// 入力待ちで止まる質問系ツール。pi-ask-user が登録する名前。
const ASK_TOOLS = new Set(["ask_user_question", "AskUserQuestion"]);

function tmux(...args: string[]): void {
  execFile("tmux", args, () => {});
}

function setState(state: string): void {
  tmux("set-option", "-p", "-t", PANE!, "@agent-status", state);
}

export default function (pi: ExtensionAPI) {
  // tmux の外や、ペインを特定できない場合は何もしない。
  if (!process.env.TMUX || !PANE) return;

  pi.on("session_start", async () => setState("idle"));
  pi.on("agent_start", async () => setState("running"));

  pi.on("tool_execution_start", async (event) => {
    if (ASK_TOOLS.has(event.toolName)) setState("blocked");
  });

  pi.on("tool_execution_end", async (event) => {
    if (ASK_TOOLS.has(event.toolName)) setState("running");
  });

  // agent_end ではなく agent_settled を使う。agent_end の後も pi は自動リトライや
  // compaction、キュー済みメッセージの続行をしうるので、そこで idle にすると早すぎる。
  pi.on("agent_settled", async () => setState("idle"));

  pi.on("session_shutdown", async () => {
    tmux("set-option", "-pu", "-t", PANE!, "@agent-status");
  });
}
