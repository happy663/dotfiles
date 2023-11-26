export declare const strip: (str: string) => string;
export declare const breakIntoWords: (str: string) => string[];
export declare const wrap: (str: string, indent?: string, max?: number) => string;
export interface Part {
    raw: string;
    prefix: string;
    text: string;
    words: string[];
}
export declare const split: (str: string) => Part[];
export declare function lines(msg: string, perLine: number): number;
export default function (prompt: string, perLine: number): string;
