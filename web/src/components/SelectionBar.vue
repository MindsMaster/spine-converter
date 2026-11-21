<script setup lang="ts">
import { Download, FileArchive, Trash2, X } from "@lucide/vue";
import { useI18n } from "vue-i18n";
import { button } from "../lib/ui";
import Tip from "./ui/Tip.vue";

defineProps<{ count: number; canDownload: boolean }>();
const emit = defineEmits<{ clear: []; download: [zip: boolean]; remove: [] }>();
const { t } = useI18n();
</script>

<template>
    <div class="flex min-h-15 flex-wrap items-center gap-x-1 gap-y-2 bg-tonal px-3 py-3 text-on-tonal">
        <Tip :label="t('selection.clear')">
            <button type="button" :class="button.icon" class="text-on-tonal! hover:bg-tonal-hover!" @click="emit('clear')">
                <X aria-hidden="true" /><span class="sr-only">{{ t("selection.clear") }}</span>
            </button>
        </Tip>
        <span class="me-auto ps-1 font-semibold tabular-nums" aria-live="polite">{{ t("selection.count", { n: count }) }}</span>
        <button type="button" :class="button.text" class="hover:bg-tonal-hover!" :disabled="!canDownload" @click="emit('download', false)">
            <Download aria-hidden="true" />{{ t("toolbar.download") }}
        </button>
        <button type="button" :class="button.text" class="hover:bg-tonal-hover!" :disabled="!canDownload" @click="emit('download', true)">
            <FileArchive aria-hidden="true" />{{ t("toolbar.downloadZip") }}
        </button>
        <button type="button" :class="button.text" class="hover:bg-tonal-hover!" @click="emit('remove')">
            <Trash2 aria-hidden="true" />{{ t("selection.remove") }}
        </button>
    </div>
</template>
