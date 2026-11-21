<script setup lang="ts">
import { FileText, Folder, Upload } from "@lucide/vue";
import { useI18n } from "vue-i18n";
import { button } from "../lib/ui";

const emit = defineEmits<{ pick: [folder: boolean] }>();
const { t } = useI18n();
</script>

<template>
    <div class="grid justify-items-center gap-3 px-6 py-16 text-center">
        <Upload class="size-10 text-ink-3" :stroke-width="1.5" aria-hidden="true" />
        <h2 class="text-lg font-medium text-balance">{{ t("empty.title") }}</h2>
        <p class="text-ink-2 text-pretty">{{ t("empty.hint") }}</p>
        <div class="mt-2 flex flex-wrap justify-center gap-3">
            <button type="button" :class="button.filled" @click="emit('pick', false)">
                <FileText aria-hidden="true" />{{ t("empty.choose") }}
            </button>
            <button type="button" :class="button.outline" @click="emit('pick', true)">
                <Folder aria-hidden="true" />{{ t("empty.chooseFolder") }}
            </button>
        </div>
    </div>
</template>
