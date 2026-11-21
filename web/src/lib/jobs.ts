import { computed, markRaw, reactive, watch } from "vue";
import type { Detection, Format } from "spine-converter";
import { ConversionError, convert, detect, type Outcome } from "./converter";
import type { OutputFile } from "./download";
import { type Entry, kindOf, stem } from "./files";

export const versions = ["3.5", "3.6", "3.7", "3.8", "4.0", "4.1", "4.2", "4.3"] as const;
export type Version = (typeof versions)[number];
export type OutputFormat = "keep" | "json" | "binary";

export interface Settings {
    target: Version;
    format: OutputFormat;
    rewrite: boolean;
    pretty: boolean;
    skipLossy: boolean;
}

export interface FileJob {
    id: number;
    name: string;
    dir: string;
    kind: "skeleton" | "atlas";
    bytes: Uint8Array;
    /** Texture names an atlas lists */
    pages: string[];
    detection: Detection | null;
    state: "queued" | "busy" | "done" | "error";
    outcome: Outcome | null;
    error: ConversionError | null;
    generation: number;
    atlasUsed: FileJob | null;
}

export interface Asset {
    id: number;
    dir: string;
    name: string;
    skeletons: FileJob[];
    atlas: FileJob | null;
    selected: boolean;
}

export interface Texture {
    name: string;
    bytes: Uint8Array;
}

export type StatusKind = "queued" | "busy" | "error" | "exact" | "lossy" | "skipped";

const settingsKey = "spc-settings";
const defaults: Settings = { target: "4.3", format: "keep", rewrite: true, pretty: false, skipLossy: false };

function loadSettings(): Settings {
    try {
        const stored = JSON.parse(localStorage.getItem(settingsKey) ?? "{}") as Partial<Settings>;
        const merged = { ...defaults, ...stored };
        if (!versions.includes(merged.target)) merged.target = defaults.target;
        return merged;
    } catch {
        return { ...defaults };
    }
}

export const settings = reactive<Settings>(loadSettings());
export const assets = reactive<Asset[]>([]);
const textures = reactive(new Map<string, Texture>());

let nextId = 0;
const running = new Set<Promise<void>>();

watch(settings, (value) => {
    try {
        localStorage.setItem(settingsKey, JSON.stringify(value));
    } catch {}
});
watch(
    () => [settings.target, settings.format, settings.rewrite, settings.pretty],
    () => assets.forEach((asset) => filesOf(asset).forEach((job) => job.error?.status !== "unknownFormat" && start(job))),
);

const key = (dir: string, name: string): string => `${dir}/${name}`;
const pagePattern = /^([^:\r\n]+\.(?:png|jpe?g|webp))[ \t]*$/gim;
const pagesOf = (bytes: Uint8Array): string[] => Array.from(new TextDecoder().decode(bytes).matchAll(pagePattern), (match) => match[1]!.trim());

export const filesOf = (asset: Asset): FileJob[] => (asset.atlas ? [...asset.skeletons, asset.atlas] : asset.skeletons);
const assetOf = (job: FileJob): Asset | undefined => assets.find((asset) => asset.atlas === job || asset.skeletons.includes(job));
const readsAtlas = (job: FileJob): boolean => job.kind === "skeleton" && job.detection?.major === 3 && job.detection.minor <= 6;

function start(job: FileJob): void {
    const task = run(job);
    running.add(task);
    void task.finally(() => running.delete(task));
}

async function run(job: FileJob): Promise<void> {
    const generation = ++job.generation;
    const current = () => generation === job.generation && assetOf(job) !== undefined;
    if (!job.outcome && !job.error) job.state = "queued";
    const slow = setTimeout(() => current() && (job.state = "busy"), 250);
    try {
        if (!job.detection) {
            const detection = await detect(job.bytes);
            if (!current()) return;
            job.detection = markRaw(detection);
            if (isSpine(job)) mergeLoneSkeletons(job.dir);
        }
        const detected = job.detection.format;
        if (detected === "unknown" || (detected === "atlas") !== (job.kind === "atlas")) throw new ConversionError("unknownFormat", "");
        const atlas = readsAtlas(job) ? (assetOf(job)?.atlas ?? null) : null;
        job.atlasUsed = atlas;
        const format: Format | undefined = detected === "atlas" || settings.format === "keep" ? undefined : settings.format;
        const outcome = await convert(job.bytes, {
            targetVersion: settings.target,
            targetFormat: format,
            prettyJson: settings.pretty,
            noRewrite: !settings.rewrite,
            atlas: atlas?.bytes,
        });
        if (!current()) return;
        job.outcome = markRaw(outcome);
        job.error = null;
        job.state = "done";
    } catch (error) {
        if (!current()) return;
        job.outcome = null;
        job.error = markRaw(error instanceof ConversionError ? error : new ConversionError("invalidArgument", String(error)));
        job.state = "error";
    } finally {
        clearTimeout(slow);
    }
}

function place(job: FileJob): void {
    for (const asset of assets) {
        if (asset.dir !== job.dir) continue;
        const index = asset.skeletons.findIndex((other) => other.name === job.name);
        if (index >= 0 && job.kind === "skeleton") return void asset.skeletons.splice(index, 1, job);
        if (asset.atlas?.name === job.name) return void (asset.atlas = job);
    }
    const name = stem(job.name);
    let asset = assets.find((other) => other.dir === job.dir && other.name === name);
    if (!asset) {
        asset = reactive<Asset>({ id: nextId++, dir: job.dir, name, skeletons: [], atlas: null, selected: false }) as Asset;
        assets.push(asset);
    }
    if (job.kind === "atlas") asset.atlas = job;
    else asset.skeletons.push(job);
}

const isSpine = (job: FileJob): boolean => job.detection?.format === "json" || job.detection?.format === "binary";

/** Atlas named after the character, skeletons after variants */
function mergeLoneSkeletons(dir: string): void {
    const local = assets.filter((asset) => asset.dir === dir);
    const withAtlas = local.filter((asset) => asset.atlas);
    for (const lone of local.filter((asset) => !asset.atlas && asset.skeletons.length > 0 && asset.skeletons.every(isSpine))) {
        const prefixed = withAtlas
            .filter((asset) => lone.name.startsWith(asset.name))
            .sort((a, b) => b.name.length - a.name.length)[0];
        const only = dir && withAtlas.length === 1 ? withAtlas[0]! : undefined;
        const target = prefixed ?? (only && !only.skeletons.some((job) => stem(job.name) === only.name) ? only : undefined);
        if (!target) continue;
        target.skeletons.push(...lone.skeletons);
        assets.splice(assets.indexOf(lone), 1);
    }
}

function refreshAtlasReaders(dirs: Iterable<string>): void {
    for (const dir of dirs) {
        for (const asset of assets) {
            if (asset.dir !== dir) continue;
            for (const job of asset.skeletons) if (job.detection && readsAtlas(job) && job.atlasUsed !== asset.atlas) start(job);
        }
    }
}

export function add(entries: Entry[]): void {
    const dirs = new Set<string>();
    const fresh: FileJob[] = [];
    for (const entry of entries) {
        const kind = kindOf(entry.name);
        if (kind === "image") {
            textures.set(key(entry.dir, entry.name), markRaw({ name: entry.name, bytes: entry.bytes }));
            continue;
        }
        if (!kind) continue;
        const job = reactive<FileJob>({
            id: nextId++,
            name: entry.name,
            dir: entry.dir,
            kind,
            bytes: markRaw(entry.bytes),
            pages: kind === "atlas" ? markRaw(pagesOf(entry.bytes)) : [],
            detection: null,
            state: "queued",
            outcome: null,
            error: null,
            generation: 0,
            atlasUsed: null,
        }) as FileJob;
        place(job);
        fresh.push(job);
        dirs.add(entry.dir);
    }
    dirs.forEach(mergeLoneSkeletons);
    fresh.forEach(start);
    refreshAtlasReaders(dirs);
}

export function remove(ids: Set<number>): void {
    for (let i = assets.length - 1; i >= 0; i--) if (ids.has(assets[i]!.id)) assets.splice(i, 1);
}

export const whenIdle = async (): Promise<void> => {
    while (running.size > 0) await Promise.allSettled([...running]);
};

export function texturesOf(asset: Asset): Texture[] {
    return (asset.atlas?.pages ?? []).map((page) => textures.get(key(asset.dir, page))).filter((texture) => texture !== undefined);
}

export const lacksAtlas = (asset: Asset): boolean => !asset.atlas && asset.skeletons.some(readsAtlas);
export const versionOf = (asset: Asset): string => asset.skeletons.find((job) => job.detection?.version)?.detection?.version ?? "";

export function statusOf(asset: Asset): { kind: StatusKind; losses: number; error: ConversionError | null } {
    const files = filesOf(asset);
    const failed = files.find((job) => job.state === "error");
    if (failed) return { kind: "error", losses: 0, error: failed.error };
    if (files.some((job) => job.state === "busy")) return { kind: "busy", losses: 0, error: null };
    if (files.some((job) => job.state === "queued")) return { kind: "queued", losses: 0, error: null };
    const losses = files.reduce((sum, job) => sum + (job.outcome?.lossCount ?? 0), 0);
    return { kind: losses === 0 ? "exact" : settings.skipLossy ? "skipped" : "lossy", losses, error: null };
}

export function canDownload(asset: Asset): boolean {
    const kind = statusOf(asset).kind;
    return kind === "exact" || kind === "lossy";
}

function outputName(job: FileJob): string {
    if (settings.format === "keep" || job.kind !== "skeleton") return job.name;
    return stem(job.name) + (settings.format === "json" ? ".json" : ".skel");
}

/** A json and skel of one skeleton share a name once converted to one format */
function uniqueOutputs(files: FileJob[]): FileJob[] {
    const byName = new Map<string, FileJob>();
    for (const job of files) {
        const name = outputName(job);
        const kept = byName.get(name);
        if (!kept || (kept.detection?.format !== settings.format && job.detection?.format === settings.format)) byName.set(name, job);
    }
    return [...byName.values()];
}

export function outputsOf(asset: Asset, withDir: boolean): OutputFile[] {
    const prefix = withDir && asset.dir ? `${asset.dir}/` : "";
    return [
        ...uniqueOutputs(filesOf(asset)).map((job) => ({ path: prefix + outputName(job), data: job.outcome!.data })),
        ...texturesOf(asset).map((texture) => ({ path: prefix + texture.name, data: texture.bytes })),
    ];
}

export const selected = computed(() => assets.filter((asset) => asset.selected));

export const tally = computed(() => {
    const counts = { exact: 0, lossy: 0, failed: 0, busy: 0 };
    for (const asset of assets) {
        const kind = statusOf(asset).kind;
        if (kind === "error") counts.failed++;
        else if (kind === "queued" || kind === "busy") counts.busy++;
        else if (kind === "exact") counts.exact++;
        else counts.lossy++;
    }
    return counts;
});
