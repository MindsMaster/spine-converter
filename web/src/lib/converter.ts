import type { ConvertOptions, Detection, Status } from "spine-converter";
import type { Outcome, Reply, Request } from "./protocol";

export type { Outcome };

export class ConversionError extends Error {
    readonly status: Status;

    constructor(status: Status, message: string) {
        super(message);
        this.status = status;
    }
}

type Pending = { resolve(value: unknown): void; reject(error: ConversionError): void };

const worker = new Worker(new URL("./worker.ts", import.meta.url), { type: "module" });
const pending = new Map<number, Pending>();
let nextId = 0;

worker.addEventListener("message", (event: MessageEvent<Reply>) => {
    const reply = event.data;
    const entry = pending.get(reply.id);
    if (!entry) return;
    pending.delete(reply.id);
    if (reply.ok) entry.resolve(reply.value);
    else entry.reject(new ConversionError(reply.status, reply.message));
});

type Body = Request extends infer R ? (R extends Request ? Omit<R, "id"> : never) : never;

function call<T>(body: Body): Promise<T> {
    const id = nextId++;
    return new Promise<T>((resolve, reject) => {
        pending.set(id, { resolve: resolve as (value: unknown) => void, reject });
        worker.postMessage({ ...body, id } as Request);
    });
}

export const libraryVersion = (): Promise<string> => call<string>({ kind: "version" });
export const detect = (data: Uint8Array): Promise<Detection> => call<Detection>({ kind: "detect", data });
export const convert = (data: Uint8Array, options: ConvertOptions): Promise<Outcome> =>
    call<Outcome>({ kind: "convert", data, options });
