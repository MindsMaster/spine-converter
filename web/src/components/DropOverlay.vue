<script setup lang="ts">
import { Upload } from "@lucide/vue";
import { useI18n } from "vue-i18n";

defineProps<{ visible: boolean }>();
const { t } = useI18n();
</script>

<template>
    <Transition name="fade">
        <div v-if="visible" class="pointer-events-none fixed inset-0 z-50 grid place-items-center bg-bg/80" aria-hidden="true">
            <div class="grid animate-[pop-in_160ms] justify-items-center gap-2 rounded-xl border-2 border-dashed border-primary bg-surface px-16 py-12 text-base font-medium shadow-sheet">
                <Upload class="size-9 text-primary" aria-hidden="true" />
                {{ t("drop") }}
            </div>
        </div>
    </Transition>
</template>
