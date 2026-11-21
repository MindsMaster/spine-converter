import { Converter, ConverterError } from "spine-converter";
import wasmUrl from "spine-converter/spine_converter.wasm?url";
import type { Reply, Request } from "./protocol";

const converter = Converter.load(wasmUrl);

self.addEventListener("message", async (event: MessageEvent<Request>) => {
    const request = event.data;
    let reply: Reply;
    try {
        const c = await converter;
        if (request.kind === "version") {
            reply = { id: request.id, ok: true, value: c.libraryVersion };
        } else if (request.kind === "detect") {
            reply = { id: request.id, ok: true, value: c.detect(request.data) };
        } else {
            const { data, report, lossCount, maxImpact } = c.convert(request.data, request.options);
            reply = { id: request.id, ok: true, value: { data, report, lossCount, maxImpact } };
        }
    } catch (error) {
        reply =
            error instanceof ConverterError
                ? { id: request.id, ok: false, status: error.status, message: error.message }
                : { id: request.id, ok: false, status: "invalidArgument", message: String(error) };
    }
    const transfer = reply.ok && typeof reply.value === "object" && "data" in reply.value ? [reply.value.data.buffer] : [];
    self.postMessage(reply, { transfer });
});
