<script setup lang="ts">
import { SwitchRoot, SwitchThumb } from "reka-ui";
import { useId } from "vue";

defineProps<{ label: string; hint?: string }>();
const model = defineModel<boolean>({ required: true });
const id = useId();
</script>

<template>
    <div class="flex items-center gap-4 px-4 py-2 transition-colors duration-100 hover:bg-hover" @click.self="model = !model">
        <label :for="id" class="flex-1 cursor-pointer">
            {{ label }}
            <span v-if="hint" class="block text-xs text-ink-2">{{ hint }}</span>
        </label>
        <SwitchRoot
            :id="id"
            v-model="model"
            class="relative h-5 w-9 shrink-0 rounded-full bg-ctl transition-colors duration-150 data-[state=checked]:bg-primary"
        >
            <SwitchThumb
                class="block size-3.5 translate-x-[0.1875rem] rounded-full bg-surface transition-transform duration-150 ease-(--ease-standard) data-[state=checked]:translate-x-[1.1875rem]"
            />
        </SwitchRoot>
    </div>
</template>
