/**
 * ConfirmPrompt Base Element
 * @param {Object} opts Options
 * @param {String} opts.message Message
 * @param {Boolean} [opts.initial] Default value (true/false)
 * @param {Stream} [opts.stdin] The Readable stream to listen to
 * @param {Stream} [opts.stdout] The Writable stream to write readline data to
 * @param {String} [opts.yes] The "Yes" label
 * @param {String} [opts.yesOption] The "Yes" option when choosing between yes/no
 * @param {String} [opts.no] The "No" label
 * @param {String} [opts.noOption] The "No" option when choosing between yes/no
 */
export default class MultiselectPrompt extends Prompt {
    label: any;
    msg: any;
    value: any[];
    choices: any;
    initialValue: any;
    cursor: any;
    reset(): void;
    reset(): void;
    exit(): void;
    abort(): void;
    done: boolean | undefined;
    aborted: boolean | undefined;
    submit(): void;
    finish(): void;
    moveCursor(n: any): void;
    toggle(): void;
    _(c: any, key: any): void;
    first(): void;
    last(): void;
    up(): void;
    down(): void;
    outputText: any;
}
import Prompt from "./prompt.js";
