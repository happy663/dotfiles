/**
 * TextPrompt Base Element
 * @param {Object} opts Options
 * @param {String} opts.message Message
 * @param {String} [opts.style='default'] Render style
 * @param {String} [opts.initial] Default value
 * @param {Function} [opts.validate] Validate function
 * @param {Stream} [opts.stdin] The Readable stream to listen to
 * @param {Stream} [opts.stdout] The Writable stream to write readline data to
 * @param {String} [opts.error] The invalid error label
 */
export default class TextPrompt extends Prompt {
    transform: {
        render: (v: any) => any;
        scale: number;
    };
    label: any;
    scale: number;
    msg: any;
    initial: any;
    validator: any;
    set value(arg: any);
    get value(): any;
    errorMsg: any;
    cursor: number;
    cursorOffset: number;
    clear: string;
    placeholder: boolean | undefined;
    rendered: any;
    _value: any;
    reset(): void;
    exit(): void;
    abort(): void;
    done: boolean | undefined;
    aborted: boolean | undefined;
    error: boolean | undefined;
    red: boolean | undefined;
    validate(): Promise<void>;
    submit(): Promise<void>;
    next(): void;
    moveCursor(n: any): void;
    _(c: any, key: any): void;
    delete(): void;
    outputError: string | undefined;
    deleteForward(): void;
    first(): void;
    last(): void;
    left(): void;
    right(): void;
    isCursorAtStart(): boolean | undefined;
    isCursorAtEnd(): boolean | undefined;
    outputText: string | undefined;
}
import Prompt from "./prompt.js";
