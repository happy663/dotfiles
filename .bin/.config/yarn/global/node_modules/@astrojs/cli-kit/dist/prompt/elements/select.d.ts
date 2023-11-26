export default class SelectPrompt extends Prompt {
    label: any;
    hint: any;
    msg: any;
    value: any;
    choices: any;
    initialValue: any;
    cursor: any;
    search: any;
    reset(): void;
    reset(): void;
    exit(): void;
    abort(): void;
    done: boolean | undefined;
    aborted: boolean | undefined;
    submit(): void;
    delete(): void;
    _(c: any, key: any): void;
    timeout: NodeJS.Timeout | undefined;
    moveCursor(n: any): void;
    first(): void;
    last(): void;
    up(): void;
    down(): void;
    highlight(label: any): any;
    outputText: any;
}
import Prompt from "./prompt.js";
