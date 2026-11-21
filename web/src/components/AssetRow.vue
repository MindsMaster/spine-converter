<script setup lang="ts">
import { Check, ClipboardList, Download, FileText, Package, X } from "@lucide/vue";
import { CheckboxIndicator, CheckboxRoot } from "reka-ui";
import { computed } from "vue";
import { useI18n } from "vue-i18n";
import { formatSize } from "../lib/format";
import { type Asset, canDownload, filesOf, lacksAtlas, texturesOf, versionOf } from "../lib/jobs";
import { button } from "../lib/ui";
import StatusCell from "./StatusCell.vue";
import Tip from "./ui/Tip.vue";

const props = defineProps<{ asset: Asset }>();
const emit = defineEmits<{ toggle: [range: boolean]; report: []; download: []; remove: [] }>();
const { t, locale } = useI18n();

const files = computed(() => filesOf(props.asset));
const single = computed(() => files.value.length === 1);
const title = computed(() => (single.value ? files.value[0]!.name : props.asset.name));
const textureCount = computed(() => texturesOf(props.asset).length);
const details = computed(() => {
    const parts: string[] = single.value
        ? [formatSize(files.value[0]!.bytes.length, locale.value)]
        : files.value.map((job) => job.name);
    if (textureCount.value > 0) parts.push(t("textures", { n: textureCount.value }, textureCount.value));
    return parts.join(t("separator"));
});
const source = computed(() => versionOf(props.asset) || "—");
const outputSize = computed(() => {
    if (files.value.some((job) => !job.outcome)) return "";
    return formatSize(files.value.reduce((sum, job) => sum + job.outcome!.data.length, 0), locale.value);
});
const hasReport = computed(() => files.value.some((job) => (job.outcome?.report.length ?? 0) > 0));
const path = computed(() => (props.asset.dir ? `${props.asset.dir}/` : "") + title.value);
const prefix = computed(() => {
    const segments = props.asset.dir ? props.asset.dir.split("/") : [];
    if (segments.at(-1) === props.asset.name) segments.pop();
    return segments.length > 0 ? `${segments.join("/")}/` : "";
});

function onRowClick(event: MouseEvent): void {
    if ((event.target as Element).closest("button, a, [data-check]")) return;
    emit("toggle", event.shiftKey);
}
</script>

<template>
    <div
        role="row"
        class="file-grid min-h-14 border-b border-outline bg-surface transition-colors duration-100 select-none last:border-b-0 hover:bg-surface-2 max-md:py-2"
        :class="{ 'bg-selected! hover:bg-selected!': asset.selected }"
        :aria-selected="asset.selected"
        @click="onRowClick"
    >
        <div role="gridcell" data-check class="grid h-full cursor-pointer place-items-center self-stretch max-md:row-span-2" @click="emit('toggle', $event.shiftKey)">
            <CheckboxRoot
                :model-value="asset.selected"
                :aria-label="title"
                class="pointer-events-none grid size-[1.125rem] place-items-center rounded-[4px] border-2 border-ctl transition-colors duration-100 data-[state=checked]:border-primary data-[state=checked]:bg-primary"
                @update:model-value="emit('toggle', false)"
                @click.stop
            >
                <CheckboxIndicator class="text-on-primary data-[state=checked]:animate-[pop-in_120ms]">
                    <Check class="size-3.5" :stroke-width="3" aria-hidden="true" />
                </CheckboxIndicator>
            </CheckboxRoot>
        </div>
        <div role="gridcell" class="flex min-w-0 items-center gap-3 pe-3">
            <FileText v-if="single" class="size-5 shrink-0 text-ink-3" aria-hidden="true" />
            <Package v-else class="size-5 shrink-0 text-ink-3" aria-hidden="true" />
            <div class="min-w-0">
                <div class="truncate font-medium" translate="no" :title="path">
                    <span v-if="prefix" class="font-normal text-ink-2">{{ prefix }}</span>{{ title }}
                </div>
                <div class="truncate text-[0.8125rem] text-ink-2" :title="details">
                    <span translate="no">{{ details }}</span>
                    <span v-if="lacksAtlas(asset)" class="text-warn">{{ t("separator") }}{{ t("missingAtlas") }}</span>
                </div>
            </div>
        </div>
        <div class="contents max-md:col-start-2 max-md:col-end-4 max-md:flex max-md:items-center max-md:gap-4">
            <div role="gridcell" class="text-ink-2 tabular-nums">{{ source }}</div>
            <div role="gridcell" class="min-w-0"><StatusCell :asset="asset" @report="emit('report')" /></div>
            <div role="gridcell" class="pe-3 text-end text-ink-2 tabular-nums max-md:pe-0 max-md:text-start">
                <Transition name="fade">
                    <span v-if="outputSize">{{ outputSize }}</span>
                </Transition>
            </div>
        </div>
        <div role="gridcell" class="col-start-6 row-start-1 flex justify-end gap-0.5 pe-3 max-md:col-start-3">
            <Transition name="fade" mode="out-in">
                <Tip v-if="hasReport" :label="t('row.report')">
                    <button type="button" :class="button.iconSmall" aria-haspopup="dialog" @click="emit('report')">
                        <ClipboardList aria-hidden="true" /><span class="sr-only">{{ t("row.report") }}</span>
                    </button>
                </Tip>
                <span v-else class="size-8 pointer-coarse:size-10" />
            </Transition>
            <Transition name="fade" mode="out-in">
                <Tip v-if="canDownload(asset)" :label="t('row.download')">
                    <button type="button" :class="button.iconSmall" @click="emit('download')">
                        <Download aria-hidden="true" /><span class="sr-only">{{ t("row.download") }}</span>
                    </button>
                </Tip>
                <span v-else class="size-8 pointer-coarse:size-10" />
            </Transition>
            <Tip :label="t('row.remove')">
                <button type="button" :class="button.iconSmall" @click="emit('remove')">
                    <X aria-hidden="true" /><span class="sr-only">{{ t("row.remove") }}</span>
                </button>
            </Tip>
        </div>
    </div>
</template>
