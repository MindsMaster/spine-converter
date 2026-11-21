<script setup lang="ts">
import { ToastDescription, ToastProvider, ToastRoot, ToastViewport } from "reka-ui";
import { toastMessage } from "../lib/toast";

function onOpen(open: boolean): void {
    if (!open) toastMessage.value = null;
}
</script>

<template>
    <ToastProvider :duration="3000" swipe-direction="up">
        <ToastRoot
            v-if="toastMessage"
            :key="toastMessage.key"
            class="rounded-lg bg-ink px-4 py-3 text-bg shadow-menu data-[state=closed]:animate-[fade-out_120ms] data-[state=open]:animate-[toast-in_180ms_var(--ease-standard)]"
            @update:open="onOpen"
        >
            <ToastDescription>{{ toastMessage.text }}</ToastDescription>
        </ToastRoot>
        <ToastViewport class="fixed top-1.5 left-1/2 z-[60] flex max-w-[calc(100vw-2rem)] -translate-x-1/2 flex-col gap-2 outline-none" />
    </ToastProvider>
</template>
