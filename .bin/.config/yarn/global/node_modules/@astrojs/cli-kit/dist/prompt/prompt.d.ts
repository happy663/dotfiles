/** @type {import('../../types').default} */
export default function prompt<T extends Readonly<import("../../types").Prompt> | readonly import("../../types").Prompt[]>(questions?: T, { onSubmit, onCancel, stdin, stdout }?: import("../../types").PromptOptions | undefined): Promise<import("../../types").Answers<T>>;
