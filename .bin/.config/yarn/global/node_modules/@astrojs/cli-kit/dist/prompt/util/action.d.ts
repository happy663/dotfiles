import type { Key } from "node:readline";
export declare const action: (key: Key, isSelect: boolean) => false | "end" | "abort" | "left" | "right" | "reset" | "submit" | "next" | "exit" | "up" | "first" | "last" | "down" | "delete" | "deleteForward" | "nextPage" | "prevPage" | "home" | undefined;
