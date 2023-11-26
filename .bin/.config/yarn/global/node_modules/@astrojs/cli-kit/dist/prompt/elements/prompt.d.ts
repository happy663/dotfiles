/// <reference types="node" />
/**
 * Base prompt skeleton
 * @param {Stream} [opts.stdin] The Readable stream to listen to
 * @param {Stream} [opts.stdout] The Writable stream to write readline data to
 */
export default class Prompt extends EventEmitter {
    constructor(opts?: {});
    firstRender: boolean;
    in: any;
    out: any;
    onRender: any;
    close: () => void;
    closed: boolean;
    bell(): void;
    fire(): void;
    render(): void;
}
import EventEmitter from "node:events";
