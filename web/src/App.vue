<script setup lang="ts">
import { TooltipProvider } from "reka-ui";
import { computed, onMounted, onUnmounted, ref, shallowRef, useTemplateRef } from "vue";
import { useI18n } from "vue-i18n";
import AppBar from "./components/AppBar.vue";
import AppToast from "./components/AppToast.vue";
import DropOverlay from "./components/DropOverlay.vue";
import EmptyState from "./components/EmptyState.vue";
import FileList from "./components/FileList.vue";
import ReportSheet from "./components/ReportSheet.vue";
import SelectionBar from "./components/SelectionBar.vue";
import Toolbar from "./components/Toolbar.vue";
import { libraryVersion } from "./lib/converter";
import { saveEach, saveFile, saveZip } from "./lib/download";
import { fromDataTransfer, fromFileList, readFiles } from "./lib/files";
import { add, type Asset, assets, canDownload, outputsOf, remove, selected, settings, whenIdle } from "./lib/jobs";
import { toast } from "./lib/toast";

const { t, locale } = useI18n();
const filesInput = useTemplateRef("files");
const folderInput = useTemplateRef("folder");
const version = ref("");
const reportAsset = shallowRef<Asset | null>(null);
const reportOpen = ref(false);
const dragging = ref(false);
let anchor: number | null = null;

void libraryVersion().then((value) => (version.value = value));
const commit = computed(() => version.value.split("+")[1]);

const anyDownloadable = computed(() => assets.some(canDownload));
const selectedDownloadable = computed(() => selected.value.some(canDownload));
const docsSuffix = computed(() => (locale.value === "zh-CN" ? ".zh-CN.md" : ".md"));

async function addPicked(picked: { file: File; dir: string }[]): Promise<void> {
    const { entries, ignored, unreadable } = await readFiles(picked);
    const notes = unreadable.map((name) => t("toast.unreadable", { name }));
    if (ignored > 0) notes.push(t("toast.ignored", { n: ignored }, ignored));
    if (notes.length > 0) toast(notes.join(t("separator")));
    add(entries);
}

function onInput(event: Event): void {
    const input = event.target as HTMLInputElement;
    if (input.files) void addPicked(fromFileList(input.files));
    input.value = "";
}

function toggle(asset: Asset, range: boolean): void {
    const index = assets.indexOf(asset);
    const from = assets.findIndex((other) => other.id === anchor);
    if (range && from >= 0) {
        const value = assets[from]!.selected;
        for (let i = Math.min(from, index); i <= Math.max(from, index); i++) assets[i]!.selected = value;
    } else {
        asset.selected = !asset.selected;
        anchor = asset.id;
    }
}

function selectAll(value: boolean): void {
    assets.forEach((asset) => (asset.selected = value));
}

function openReport(asset: Asset): void {
    reportAsset.value = asset;
    reportOpen.value = true;
}

async function download(targets: Asset[], zip: boolean): Promise<void> {
    await whenIdle();
    const files = targets.filter(canDownload).flatMap((asset) => outputsOf(asset, true));
    if (files.length === 0) return;
    if (zip) saveZip(files, `spine-${settings.target}.zip`);
    else await saveEach(files);
}

async function downloadOne(asset: Asset): Promise<void> {
    await whenIdle();
    if (!canDownload(asset)) return;
    const files = outputsOf(asset, false);
    if (files.length === 1) saveFile(files[0]!);
    else saveZip(files, `${asset.name}.zip`);
}

let depth = 0;
const hasFiles = (event: DragEvent) => event.dataTransfer?.types.includes("Files") ?? false;
function onDragEnter(event: DragEvent): void {
    if (!hasFiles(event)) return;
    event.preventDefault();
    depth++;
    dragging.value = true;
}
function onDragOver(event: DragEvent): void {
    if (!hasFiles(event)) return;
    event.preventDefault();
    event.dataTransfer!.dropEffect = "copy";
}
function onDragLeave(): void {
    if (--depth <= 0) {
        depth = 0;
        dragging.value = false;
    }
}
async function onDrop(event: DragEvent): Promise<void> {
    if (!hasFiles(event)) return;
    event.preventDefault();
    depth = 0;
    dragging.value = false;
    await addPicked(await fromDataTransfer(event.dataTransfer!));
}

onMounted(() => {
    addEventListener("dragenter", onDragEnter);
    addEventListener("dragover", onDragOver);
    addEventListener("dragleave", onDragLeave);
    addEventListener("drop", onDrop);
});
onUnmounted(() => {
    removeEventListener("dragenter", onDragEnter);
    removeEventListener("dragover", onDragOver);
    removeEventListener("dragleave", onDragLeave);
    removeEventListener("drop", onDrop);
});
</script>

<template>
    <TooltipProvider :delay-duration="500">
        <div class="flex min-h-dvh flex-col">
            <AppBar />
            <main class="mx-auto w-full max-w-6xl flex-1 px-4 py-6 md:px-6 md:py-8">
                <h1 class="sr-only">spine-converter</h1>
                <section class="overflow-clip rounded-xl border border-outline bg-surface">
                    <div class="grid *:col-start-1 *:row-start-1">
                        <Transition name="swap">
                            <SelectionBar
                                v-if="selected.length > 0"
                                :count="selected.length"
                                :can-download="selectedDownloadable"
                                @clear="selectAll(false)"
                                @download="(zip) => download(selected, zip)"
                                @remove="remove(new Set(selected.map((asset) => asset.id)))"
                            />
                            <Toolbar v-else :can-download="anyDownloadable" @pick="(folder) => (folder ? folderInput : filesInput)?.click()" @download="(zip) => download(assets, zip)" />
                        </Transition>
                    </div>
                    <Transition name="fade" mode="out-in">
                        <EmptyState v-if="assets.length === 0" class="border-t border-outline" @pick="(folder) => (folder ? folderInput : filesInput)?.click()" />
                        <FileList
                            v-else
                            @toggle="toggle"
                            @select-all="selectAll"
                            @report="openReport"
                            @download="downloadOne"
                            @remove="(asset) => remove(new Set([asset.id]))"
                        />
                    </Transition>
                </section>
            </main>
            <footer class="flex flex-wrap justify-center gap-x-5 gap-y-1 px-4 pb-6 text-xs text-ink-2">
                <a v-if="commit" class="underline underline-offset-2 hover:text-ink" :href="`https://github.com/MindsMaster/spine-converter/commit/${commit}`" translate="no">
                    spine-converter {{ version.split("+")[0] }}+{{ commit.slice(0, 7) }}
                </a>
                <span v-else-if="version" translate="no">spine-converter {{ version }}</span>
                <span>{{ t("footer.unofficial") }}</span>
                <a class="underline underline-offset-2 hover:text-ink" href="https://github.com/MindsMaster/spine-converter">GitHub</a>
                <a class="underline underline-offset-2 hover:text-ink" href="https://github.com/MindsMaster/spine-converter/blob/main/LICENSE">{{ t("footer.license") }}</a>
                <a class="underline underline-offset-2 hover:text-ink" :href="`https://github.com/MindsMaster/spine-converter/blob/main/docs/report${docsSuffix}`">
                    {{ t("footer.reportDoc") }}
                </a>
            </footer>
        </div>
        <input ref="files" type="file" class="sr-only" tabindex="-1" aria-hidden="true" multiple accept=".json,.skel,.atlas,.txt,.bytes,.png,.jpg,.jpeg,.webp,.zip" @change="onInput" />
        <input ref="folder" type="file" class="sr-only" tabindex="-1" aria-hidden="true" webkitdirectory @change="onInput" />
        <ReportSheet v-model:open="reportOpen" :asset="reportAsset" />
        <DropOverlay :visible="dragging" />
        <AppToast />
    </TooltipProvider>
</template>
