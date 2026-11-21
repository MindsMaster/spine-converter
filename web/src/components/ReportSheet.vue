<script setup lang="ts">
import { X } from "@lucide/vue";
import { DialogClose, DialogContent, DialogDescription, DialogOverlay, DialogPortal, DialogRoot, DialogTitle } from "reka-ui";
import type { ReportEntry } from "spine-converter";
import { computed, shallowRef, watch } from "vue";
import { useI18n } from "vue-i18n";
import { type Asset, filesOf, settings, versionOf } from "../lib/jobs";
import { button } from "../lib/ui";

const props = defineProps<{ asset: Asset | null }>();
const open = defineModel<boolean>("open", { required: true });
const { t, locale } = useI18n();

const meanings = shallowRef<ReadonlyMap<string, string>>(new Map());
watch(
    [open, locale],
    async () => {
        if (open.value && locale.value === "zh-CN" && meanings.value.size === 0) meanings.value = (await import("../lib/codes")).meaningsZh;
    },
    { immediate: true },
);

interface Group {
    key: string;
    impact: ReportEntry["impact"];
    severity: ReportEntry["severity"];
    text: string;
    runtime: boolean;
    paths: string[];
    count: number;
}

function groupSteps(report: readonly ReportEntry[], zh: boolean) {
    const byStep = new Map<string, Map<string, Group>>();
    for (const entry of report) {
        const text = (zh && meanings.value.get(entry.code)) || entry.message;
        const key = `${entry.code}\n${text}\n${entry.remedy}`;
        const groups = byStep.get(entry.step) ?? byStep.set(entry.step, new Map()).get(entry.step)!;
        const group =
            groups.get(key) ??
            groups
                .set(key, { key, impact: entry.impact, severity: entry.severity, text, runtime: entry.remedy === "runtime", paths: [], count: 0 })
                .get(key)!;
        group.count++;
        if (group.paths.length < 3 && entry.path) group.paths.push(entry.path);
    }
    return [...byStep].map(([step, groups]) => ({ step: step.replace("-", " → "), groups: [...groups.values()] }));
}

const sections = computed(() => {
    const zh = locale.value === "zh-CN";
    return (props.asset ? filesOf(props.asset) : [])
        .filter((job) => (job.outcome?.report.length ?? 0) > 0)
        .map((job) => ({ file: job.name, steps: groupSteps(job.outcome!.report, zh) }));
});

const tagClass: Record<ReportEntry["impact"], string> = {
    none: "bg-surface-2 text-ink-2",
    editor: "bg-surface-2 text-ink-2",
    control: "bg-bad-bg text-bad",
    pose: "bg-warn-bg text-warn",
    render: "bg-warn-bg text-warn",
};
</script>

<template>
    <DialogRoot v-model:open="open">
        <DialogPortal>
            <DialogOverlay class="fixed inset-0 z-40 bg-scrim data-[state=closed]:animate-[fade-out_160ms] data-[state=open]:animate-[fade-in_200ms]" />
            <DialogContent
                class="fixed inset-y-0 end-0 z-40 flex w-[min(40rem,100vw)] flex-col border-s border-outline bg-surface shadow-sheet outline-none data-[state=closed]:animate-[sheet-out_180ms_ease-in] data-[state=open]:animate-[sheet-in_240ms_var(--ease-standard)]"
            >
                <header class="flex items-center gap-3 border-b border-outline py-3 ps-5 pe-3">
                    <div class="min-w-0">
                        <DialogTitle class="truncate text-base font-medium" translate="no">{{ asset?.name }}</DialogTitle>
                        <DialogDescription class="text-[0.8125rem] text-ink-2 tabular-nums">
                            {{ asset && versionOf(asset) ? `${versionOf(asset)} → ` : "" }}{{ settings.target }}
                        </DialogDescription>
                    </div>
                    <DialogClose :class="button.icon" class="ms-auto">
                        <X aria-hidden="true" /><span class="sr-only">{{ t("report.close") }}</span>
                    </DialogClose>
                </header>
                <div class="flex-1 overflow-y-auto overscroll-contain">
                    <p v-if="sections.length === 0" class="p-5 text-ink-2">{{ t("report.none") }}</p>
                    <section v-for="section in sections" :key="section.file">
                    <h3 v-if="sections.length > 1" class="border-b border-outline px-5 pt-4 pb-2 font-medium" translate="no">{{ section.file }}</h3>
                    <table class="w-full border-collapse">
                        <thead class="sticky top-0 z-10 bg-surface">
                            <tr class="text-[0.8125rem] text-ink-2">
                                <th class="border-b border-outline py-2 ps-5 pe-3 text-start font-medium whitespace-nowrap">{{ t("report.impact") }}</th>
                                <th class="border-b border-outline px-3 py-2 text-start font-medium">{{ t("report.change") }}</th>
                                <th class="border-b border-outline py-2 ps-3 pe-5 text-end font-medium whitespace-nowrap">{{ t("report.count") }}</th>
                            </tr>
                        </thead>
                        <tbody v-for="step in section.steps" :key="step.step">
                            <tr v-if="step.step">
                                <th colspan="3" class="border-b border-outline bg-surface-2 py-1.5 ps-5 text-start font-medium text-ink-2 tabular-nums">
                                    {{ step.step }}
                                </th>
                            </tr>
                            <tr v-for="group in step.groups" :key="group.key" class="align-top">
                                <td class="border-b border-outline py-2.5 ps-5 pe-3">
                                    <span class="inline-block rounded px-2 text-xs leading-5 font-medium whitespace-nowrap" :class="tagClass[group.impact]">
                                        {{ t(`report.impacts.${group.impact}`) }}
                                    </span>
                                </td>
                                <td class="border-b border-outline px-3 py-2.5">
                                    <div>{{ t(`report.severities.${group.severity}`) }}{{ locale === "zh-CN" ? "：" : ": " }}{{ group.text }}</div>
                                    <div v-if="group.runtime" class="text-[0.8125rem] text-ink-2">{{ t("report.runtime") }}</div>
                                    <code v-for="path in group.paths" :key="path" class="block font-mono text-xs break-all text-ink-2" translate="no">{{ path }}</code>
                                    <div v-if="group.count > group.paths.length" class="text-[0.8125rem] text-ink-2">
                                        {{ t("report.more", { n: group.count - group.paths.length }) }}
                                    </div>
                                </td>
                                <td class="border-b border-outline py-2.5 ps-3 pe-5 text-end tabular-nums">{{ group.count }}</td>
                            </tr>
                        </tbody>
                    </table>
                    </section>
                </div>
            </DialogContent>
        </DialogPortal>
    </DialogRoot>
</template>
