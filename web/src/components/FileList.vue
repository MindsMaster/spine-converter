<script setup lang="ts">
import { Check, Minus } from "@lucide/vue";
import { CheckboxIndicator, CheckboxRoot } from "reka-ui";
import { computed } from "vue";
import { useI18n } from "vue-i18n";
import { type Asset, assets, tally } from "../lib/jobs";
import AssetRow from "./AssetRow.vue";

const emit = defineEmits<{ toggle: [asset: Asset, range: boolean]; selectAll: [value: boolean]; report: [asset: Asset]; download: [asset: Asset]; remove: [asset: Asset] }>();
const { t } = useI18n();

const all = computed<boolean | "indeterminate">(() => {
    const count = assets.filter((asset) => asset.selected).length;
    return count === 0 ? false : count === assets.length ? true : "indeterminate";
});
const counts = computed(() =>
    (["exact", "lossy", "failed", "busy"] as const)
        .map((key) => ({ key, n: tally.value[key] }))
        .filter((item) => item.n > 0),
);
const dot = { exact: "bg-ok", lossy: "bg-warn", failed: "bg-bad", busy: "bg-ink-3" } as const;
</script>

<template>
    <div role="grid" aria-multiselectable="true" :aria-label="t('table.name')" :aria-rowcount="assets.length + 1">
        <div role="row" class="file-grid h-10 border-y border-outline text-[0.8125rem] font-medium text-ink-2">
            <div role="columnheader" class="grid h-full cursor-pointer place-items-center" @click="emit('selectAll', all !== true)">
                <CheckboxRoot
                    :model-value="all"
                    :aria-label="t('table.selectAll')"
                    class="pointer-events-none grid size-[1.125rem] place-items-center rounded-[4px] border-2 border-ctl transition-colors duration-100 data-[state=checked]:border-primary data-[state=checked]:bg-primary data-[state=indeterminate]:border-primary data-[state=indeterminate]:bg-primary"
                    @update:model-value="emit('selectAll', all !== true)"
                    @click.stop
                >
                    <CheckboxIndicator class="text-on-primary">
                        <Minus v-if="all === 'indeterminate'" class="size-3.5" :stroke-width="3" aria-hidden="true" />
                        <Check v-else class="size-3.5" :stroke-width="3" aria-hidden="true" />
                    </CheckboxIndicator>
                </CheckboxRoot>
            </div>
            <div role="columnheader">{{ t("table.name") }}</div>
            <div role="columnheader" class="max-md:hidden">{{ t("table.source") }}</div>
            <div role="columnheader" class="max-md:hidden">{{ t("table.status") }}</div>
            <div role="columnheader" class="pe-3 text-end max-md:hidden">{{ t("table.size") }}</div>
            <div role="columnheader" class="max-md:hidden"><span class="sr-only">{{ t("row.download") }}</span></div>
        </div>
        <TransitionGroup tag="div" role="rowgroup" name="row" class="relative">
            <AssetRow
                v-for="asset in assets"
                :key="asset.id"
                :asset="asset"
                @toggle="(range) => emit('toggle', asset, range)"
                @report="emit('report', asset)"
                @download="emit('download', asset)"
                @remove="emit('remove', asset)"
            />
        </TransitionGroup>
    </div>
    <div class="flex min-h-12 flex-wrap items-center gap-x-4 gap-y-1 border-t border-outline px-4 py-2.5 text-ink-2 tabular-nums" aria-live="polite">
        <span>{{ t("tally.files", { n: assets.length }, assets.length) }}</span>
        <span v-for="item in counts" :key="item.key" class="inline-flex items-center gap-1.5">
            <span class="size-2 rounded-full" :class="dot[item.key]" aria-hidden="true" />{{ t(`tally.${item.key}`, { n: item.n }) }}
        </span>
    </div>
</template>
