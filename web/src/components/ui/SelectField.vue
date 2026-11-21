<script setup lang="ts" generic="T extends string">
import { Check, ChevronDown } from "@lucide/vue";
import {
    SelectContent,
    SelectItem,
    SelectItemIndicator,
    SelectItemText,
    SelectPortal,
    SelectRoot,
    SelectTrigger,
    SelectValue,
    SelectViewport,
} from "reka-ui";
import { computed } from "vue";

const props = defineProps<{ label: string; options: readonly { value: T; label: string }[] }>();
const model = defineModel<T>({ required: true });
const selected = computed(() => props.options.find((option) => option.value === model.value)?.label);
</script>

<template>
    <SelectRoot v-model="model">
        <SelectTrigger
            class="inline-flex h-9 items-center gap-2 rounded-lg border border-ctl bg-surface pr-2 pl-3 transition-colors duration-100 hover:bg-hover data-[state=open]:border-primary data-[state=open]:shadow-[inset_0_0_0_1px_var(--primary)]"
        >
            <span class="text-ink-2">{{ label }}</span>
            <SelectValue class="font-medium">{{ selected }}</SelectValue>
            <ChevronDown class="size-4 text-ink-2" aria-hidden="true" />
        </SelectTrigger>
        <SelectPortal>
            <SelectContent position="popper" :side-offset="4" class="floating z-50 min-w-(--reka-select-trigger-width)">
                <SelectViewport>
                    <SelectItem v-for="option in options" :key="option.value" :value="option.value" class="menu-item">
                        <SelectItemText>{{ option.label }}</SelectItemText>
                        <SelectItemIndicator class="ms-auto">
                            <Check class="size-4" aria-hidden="true" />
                        </SelectItemIndicator>
                    </SelectItem>
                </SelectViewport>
            </SelectContent>
        </SelectPortal>
    </SelectRoot>
</template>
