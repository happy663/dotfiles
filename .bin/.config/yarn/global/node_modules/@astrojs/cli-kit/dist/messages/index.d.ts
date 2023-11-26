/// <reference types="node" />
export declare const say: (messages?: string | string[], { clear, hat, stdin, stdout }?: {
    clear?: boolean | undefined;
    hat?: string | undefined;
    stdin?: (NodeJS.ReadStream & {
        fd: 0;
    }) | undefined;
    stdout?: (NodeJS.WriteStream & {
        fd: 1;
    }) | undefined;
}) => Promise<void>;
export declare const label: (text: string, c?: import("chalk").ChalkInstance, t?: import("chalk").ChalkInstance) => string;
