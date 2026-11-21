import { unzipSync } from "fflate";

export interface Entry {
    name: string;
    /** Empty for loose files */
    dir: string;
    bytes: Uint8Array;
}

interface Picked {
    file: File;
    dir: string;
}

export type Kind = "skeleton" | "atlas" | "image";

export function kindOf(name: string): Kind | null {
    if (/\.atlas(\.txt)?$/i.test(name)) return "atlas";
    if (/\.(json|skel)(\.bytes|\.txt)?$/i.test(name)) return "skeleton";
    if (/\.(png|jpe?g|webp)$/i.test(name)) return "image";
    return null;
}

export const stem = (name: string): string => name.replace(/\.(json|skel|atlas)(\.txt|\.bytes)?$/i, "");

export async function readFiles(files: Picked[]): Promise<{ entries: Entry[]; ignored: number; unreadable: string[] }> {
    const entries: Entry[] = [];
    const unreadable: string[] = [];
    let ignored = 0;
    for (const { file, dir } of files) {
        if (/\.zip$/i.test(file.name)) {
            let archive: Record<string, Uint8Array>;
            try {
                archive = unzipSync(new Uint8Array(await file.arrayBuffer()));
            } catch {
                unreadable.push(file.name);
                continue;
            }
            for (const [path, bytes] of Object.entries(archive)) {
                if (path.endsWith("/") || path.startsWith("__MACOSX/")) continue;
                const name = path.slice(path.lastIndexOf("/") + 1);
                if (kindOf(name)) entries.push({ name, dir: joinDir(dir, dirOf(path)), bytes });
                else ignored++;
            }
        } else if (kindOf(file.name)) {
            entries.push({ name: file.name, dir, bytes: new Uint8Array(await file.arrayBuffer()) });
        } else {
            ignored++;
        }
    }
    return { entries, ignored, unreadable };
}

export function fromFileList(list: FileList): Picked[] {
    return Array.from(list, (file) => ({ file, dir: dirOf(file.webkitRelativePath) }));
}

export async function fromDataTransfer(transfer: DataTransfer): Promise<Picked[]> {
    const roots = Array.from(transfer.items, (item) => item.webkitGetAsEntry()).filter((entry) => entry !== null);
    if (roots.length === 0) return Array.from(transfer.files, (file) => ({ file, dir: "" }));
    const out: Picked[] = [];
    await Promise.all(roots.map((entry) => walk(entry, out)));
    return out;
}

async function walk(entry: FileSystemEntry, out: Picked[]): Promise<void> {
    if (entry.isFile) {
        const file = await new Promise<File>((resolve, reject) => (entry as FileSystemFileEntry).file(resolve, reject));
        out.push({ file, dir: dirOf(entry.fullPath.replace(/^\//, "")) });
        return;
    }
    const reader = (entry as FileSystemDirectoryEntry).createReader();
    for (;;) {
        // readEntries returns at most 100 entries per call in Chromium
        const batch = await new Promise<FileSystemEntry[]>((resolve, reject) => reader.readEntries(resolve, reject));
        if (batch.length === 0) break;
        await Promise.all(batch.map((child) => walk(child, out)));
    }
}

function dirOf(path: string): string {
    const slash = path.lastIndexOf("/");
    return slash < 0 ? "" : path.slice(0, slash);
}

const joinDir = (a: string, b: string): string => (a && b ? `${a}/${b}` : a || b);
