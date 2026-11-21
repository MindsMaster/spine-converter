import { zipSync } from "fflate";

export interface OutputFile {
    path: string;
    data: Uint8Array;
}

export function save(blob: Blob, name: string): void {
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = url;
    link.download = name;
    link.click();
    setTimeout(() => URL.revokeObjectURL(url), 60_000);
}

export const saveFile = (file: OutputFile): void => save(new Blob([file.data as Uint8Array<ArrayBuffer>]), baseName(file.path));

export async function saveEach(files: OutputFile[]): Promise<void> {
    for (const file of files) {
        saveFile(file);
        // Browsers drop clicks that arrive in the same task
        await new Promise((resolve) => setTimeout(resolve, 150));
    }
}

export function saveZip(files: OutputFile[], name: string): void {
    const entries: Record<string, Uint8Array> = {};
    for (const file of files) entries[unique(entries, file.path)] = file.data;
    save(new Blob([zipSync(entries, { level: 6 }) as Uint8Array<ArrayBuffer>], { type: "application/zip" }), name);
}

function unique(taken: Record<string, unknown>, path: string): string {
    if (!(path in taken)) return path;
    const dot = path.lastIndexOf(".");
    const [stem, ext] = dot > path.lastIndexOf("/") ? [path.slice(0, dot), path.slice(dot)] : [path, ""];
    for (let n = 2; ; n++) if (!(`${stem} (${n})${ext}` in taken)) return `${stem} (${n})${ext}`;
}

const baseName = (path: string): string => path.slice(path.lastIndexOf("/") + 1);
