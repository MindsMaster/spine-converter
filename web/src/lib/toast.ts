import { shallowRef } from "vue";

export const toastMessage = shallowRef<{ text: string; key: number } | null>(null);

let key = 0;

export function toast(text: string): void {
    toastMessage.value = { text, key: key++ };
}
