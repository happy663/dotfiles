/// <reference types="node" />
export declare function forceUnicode(): void;
export declare const useAscii: () => boolean;
export declare const hookExit: () => () => NodeJS.Process;
export declare const sleep: (ms: number) => Promise<unknown>;
export declare const random: (...arr: any[]) => any;
export declare const randomBetween: (min: number, max: number) => number;
export declare const getAstroVersion: () => Promise<string>;
export declare const getUserName: () => Promise<string>;
export declare const align: (text: string, dir: 'start' | 'end' | 'center', len: number) => string;
