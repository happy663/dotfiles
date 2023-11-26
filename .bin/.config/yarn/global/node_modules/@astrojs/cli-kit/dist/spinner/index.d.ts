/// <reference types="node" />
export declare function spinner({ start, end, while: update, }: {
    start: string;
    end: string;
    while: (...args: any) => Promise<any>;
}, { stdin, stdout }?: {
    stdin?: (NodeJS.ReadStream & {
        fd: 0;
    }) | undefined;
    stdout?: (NodeJS.WriteStream & {
        fd: 1;
    }) | undefined;
}): Promise<void>;
