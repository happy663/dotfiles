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
export default class ConfirmPrompt extends Prompt {
    label: any;
    hint: any;
    msg: any;
    value: any;
    initialValue: boolean;
    choices: {
        value: boolean;
        label: string;
    }[];
    cursor: number;
    reset(): void;
    reset(): void;
    exit(): void;
    abort(): void;
    done: boolean | undefined;
    aborted: boolean | undefined;
    submit(): void;
    moveCursor(n: any): void;
    first(): void;
    last(): void;
    left(): void;
    right(): void;
    _(c: any, key: any): void;
    outputText: any;
}
import Prompt from "./prompt.js";
