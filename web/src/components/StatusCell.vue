<script setup lang="ts">
import { Check, CircleX, LoaderCircle, TriangleAlert } from "@lucide/vue";
import { computed } from "vue";
import { useI18n } from "vue-i18n";
import { type Asset, statusOf } from "../lib/jobs";

const props = defineProps<{ asset: Asset }>();
const emit = defineEmits<{ report: [] }>();
const { t } = useI18n();

const errorKeys = new Set(["unknownFormat", "unsupportedVersion", "malformed"]);
const status = computed(() => statusOf(props.asset));
const errorText = computed(() => {
    const code = status.value.error?.status ?? "";
    return t(errorKeys.has(code) ? `status.${code}` : "status.failed");
});
</script>

<template>
    <Transition name="swap" mode="out-in">
        <span v-if="status.kind === 'queued'" key="queued" />
        <span v-else-if="status.kind === 'busy'" key="busy" class="inline-flex items-center gap-1.5 text-ink-2">
            <LoaderCircle class="size-4 animate-spin text-primary" aria-hidden="true" />{{ t("status.busy") }}
        </span>
        <span v-else-if="status.kind === 'error'" key="error" class="inline-flex items-center gap-1.5 text-bad" :title="status.error?.message || undefined">
            <CircleX class="size-4 shrink-0" aria-hidden="true" />{{ errorText }}
        </span>
        <button
            v-else-if="status.kind === 'lossy' || status.kind === 'skipped'"
            :key="status.kind"
            type="button"
            class="-ms-1.5 inline-flex items-center gap-1.5 rounded-md px-1.5 py-1 text-start text-warn transition-colors duration-100 hover:bg-warn-bg"
            aria-haspopup="dialog"
            @click="emit('report')"
        >
            <TriangleAlert class="size-4 shrink-0" aria-hidden="true" />{{ t(`status.${status.kind}`, { n: status.losses }, status.losses) }}
        </button>
        <span v-else key="exact" class="inline-flex items-center gap-1.5 text-ok">
            <Check class="size-4" aria-hidden="true" />{{ t("status.exact") }}
        </span>
    </Transition>
</template>
