<script setup lang="ts">
import { ChevronDown, Download, FileArchive, FileText, Folder, Plus, SlidersHorizontal } from "@lucide/vue";
import {
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuPortal,
    DropdownMenuRoot,
    DropdownMenuTrigger,
    PopoverContent,
    PopoverPortal,
    PopoverRoot,
    PopoverTrigger,
} from "reka-ui";
import { computed } from "vue";
import { useI18n } from "vue-i18n";
import { type OutputFormat, settings, versions } from "../lib/jobs";
import { button } from "../lib/ui";
import OptionSwitch from "./OptionSwitch.vue";
import SelectField from "./ui/SelectField.vue";

defineProps<{ canDownload: boolean }>();
const emit = defineEmits<{ pick: [folder: boolean]; download: [zip: boolean] }>();
const { t } = useI18n();

const changed = computed(() => Number(!settings.rewrite) + Number(settings.pretty) + Number(settings.skipLossy));
const targets = versions.map((value) => ({ value, label: `Spine ${value}` }));
const formats = computed(() =>
    (["keep", "json", "binary"] as const satisfies readonly OutputFormat[]).map((value) => ({ value, label: t(`formats.${value}`) })),
);
</script>

<template>
    <div class="flex flex-wrap items-center gap-x-3 gap-y-2 px-4 py-3">
        <DropdownMenuRoot>
            <DropdownMenuTrigger :class="button.outline" class="ps-3">
                <Plus aria-hidden="true" />
                {{ t("toolbar.add") }}
            </DropdownMenuTrigger>
            <DropdownMenuPortal>
                <DropdownMenuContent align="start" :side-offset="4" class="floating z-50">
                    <DropdownMenuItem class="menu-item" @select="emit('pick', false)">
                        <FileText class="size-5 text-ink-2" aria-hidden="true" />{{ t("toolbar.addFiles") }}
                    </DropdownMenuItem>
                    <DropdownMenuItem class="menu-item" @select="emit('pick', true)">
                        <Folder class="size-5 text-ink-2" aria-hidden="true" />{{ t("toolbar.addFolder") }}
                    </DropdownMenuItem>
                </DropdownMenuContent>
            </DropdownMenuPortal>
        </DropdownMenuRoot>
        <span class="h-6 w-px bg-outline max-sm:hidden" aria-hidden="true" />
        <SelectField v-model="settings.target" :label="t('toolbar.target')" :options="targets" />
        <SelectField v-model="settings.format" :label="t('toolbar.format')" :options="formats" />
        <PopoverRoot>
            <PopoverTrigger :class="button.text" class="data-[state=open]:bg-hover">
                <SlidersHorizontal aria-hidden="true" />
                {{ t("toolbar.options") }}
                <Transition name="fade">
                    <span v-if="changed > 0" class="grid size-5 place-items-center rounded-full bg-primary text-xs text-on-primary tabular-nums">{{ changed }}</span>
                </Transition>
            </PopoverTrigger>
            <PopoverPortal>
                <PopoverContent align="start" :side-offset="4" class="floating z-50 w-80 py-2" :aria-label="t('toolbar.options')">
                    <OptionSwitch v-model="settings.rewrite" :label="t('options.rewrite')" :hint="t('options.rewriteHint')" />
                    <OptionSwitch v-model="settings.pretty" :label="t('options.pretty')" :hint="t('options.prettyHint')" />
                    <OptionSwitch v-model="settings.skipLossy" :label="t('options.skipLossy')" :hint="t('options.skipLossyHint')" />
                </PopoverContent>
            </PopoverPortal>
        </PopoverRoot>
        <DropdownMenuRoot>
            <DropdownMenuTrigger :class="button.filled" class="ms-auto ps-3 pe-3" :disabled="!canDownload">
                <Download aria-hidden="true" />
                {{ t("toolbar.download") }}
                <ChevronDown class="size-4!" aria-hidden="true" />
            </DropdownMenuTrigger>
            <DropdownMenuPortal>
                <DropdownMenuContent align="end" :side-offset="4" class="floating z-50">
                    <DropdownMenuItem class="menu-item" @select="emit('download', true)">
                        <FileArchive class="size-5 text-ink-2" aria-hidden="true" />{{ t("toolbar.downloadZip") }}
                    </DropdownMenuItem>
                    <DropdownMenuItem class="menu-item" @select="emit('download', false)">
                        <Download class="size-5 text-ink-2" aria-hidden="true" />{{ t("toolbar.downloadEach") }}
                    </DropdownMenuItem>
                </DropdownMenuContent>
            </DropdownMenuPortal>
        </DropdownMenuRoot>
    </div>
</template>
