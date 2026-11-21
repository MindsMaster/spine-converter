<script setup lang="ts">
import { TooltipContent, TooltipPortal, TooltipRoot, TooltipTrigger } from "reka-ui";

defineProps<{ label: string }>();
</script>

<template>
    <TooltipRoot>
        <TooltipTrigger as-child>
            <slot />
        </TooltipTrigger>
        <TooltipPortal>
            <TooltipContent
                :side-offset="6"
                class="z-50 rounded-md bg-ink px-2 py-1 text-xs text-bg data-[state=closed]:animate-[fade-out_80ms] data-[state=delayed-open]:animate-[fade-in_120ms] data-[state=instant-open]:animate-[fade-in_80ms]"
            >
                {{ label }}
            </TooltipContent>
        </TooltipPortal>
    </TooltipRoot>
</template>
