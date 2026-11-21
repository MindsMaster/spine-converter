import type { ConvertOptions, Detection, Impact, ReportEntry, Status } from "spine-converter";

export type Request =
    | { id: number; kind: "version" }
    | { id: number; kind: "detect"; data: Uint8Array }
    | { id: number; kind: "convert"; data: Uint8Array; options: ConvertOptions };

export interface Outcome {
    data: Uint8Array;
    report: ReportEntry[];
    lossCount: number;
    maxImpact: Impact;
}

export type Reply =
    | { id: number; ok: true; value: string | Detection | Outcome }
    | { id: number; ok: false; status: Status; message: string };
