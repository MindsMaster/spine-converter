<script setup lang="ts">
import { Check, ChevronDown, Languages, Moon, Sun, SunMoon } from "@lucide/vue";
import {
    DropdownMenuContent,
    DropdownMenuItemIndicator,
    DropdownMenuPortal,
    DropdownMenuRadioGroup,
    DropdownMenuRadioItem,
    DropdownMenuRoot,
    DropdownMenuSeparator,
    DropdownMenuTrigger,
} from "reka-ui";
import { computed } from "vue";
import { useI18n } from "vue-i18n";
import { type LocalePreference, localePreference, locales, setLocale } from "../i18n";
import { preference, type SchemePreference, setScheme } from "../lib/theme";
import { button } from "../lib/ui";
import icon from "../../../.github/icon.svg";

const { t, locale } = useI18n();
const language = computed({ get: () => localePreference.value, set: (value: LocalePreference) => setLocale(value) });
const theme = computed({ get: () => preference.value, set: (value: SchemePreference) => setScheme(value) });
const languageLabel = computed(() => locales.find((item) => item.code === locale.value)!.label);
const themes = computed(() => [
    { value: "system" as const, label: t("bar.system"), icon: SunMoon },
    { value: "light" as const, label: t("bar.light"), icon: Sun },
    { value: "dark" as const, label: t("bar.dark"), icon: Moon },
]);
const themeIcon = computed(() => themes.value.find((item) => item.value === preference.value)!.icon);
const trigger = `${button.text} text-ink-2 hover:text-ink data-[state=open]:bg-hover data-[state=open]:text-ink`;
</script>

<template>
    <header class="flex h-14 items-center gap-1 border-b border-outline bg-surface ps-4 pe-3">
        <a href="./" class="me-auto flex items-center gap-2.5 text-[1.0625rem] font-medium" translate="no">
            <img :src="icon" alt="" class="size-7" />
            spine-converter
        </a>
        <DropdownMenuRoot>
            <DropdownMenuTrigger :class="trigger" class="px-2.5">
                <component :is="themeIcon" aria-hidden="true" />
                <span class="sr-only">{{ t("bar.theme") }}</span>
                <ChevronDown class="size-4! max-sm:hidden" aria-hidden="true" />
            </DropdownMenuTrigger>
            <DropdownMenuPortal>
                <DropdownMenuContent align="end" :side-offset="4" class="floating z-50">
                    <DropdownMenuRadioGroup v-model="theme">
                        <DropdownMenuRadioItem v-for="item in themes" :key="item.value" :value="item.value" class="menu-item">
                            <component :is="item.icon" class="size-5 text-ink-2" aria-hidden="true" />
                            {{ item.label }}
                            <DropdownMenuItemIndicator class="ms-auto ps-4"><Check class="size-4" aria-hidden="true" /></DropdownMenuItemIndicator>
                        </DropdownMenuRadioItem>
                    </DropdownMenuRadioGroup>
                </DropdownMenuContent>
            </DropdownMenuPortal>
        </DropdownMenuRoot>
        <DropdownMenuRoot>
            <DropdownMenuTrigger :class="trigger" class="px-2.5">
                <Languages aria-hidden="true" />
                <span class="max-sm:sr-only">{{ languageLabel }}</span>
                <ChevronDown class="size-4! max-sm:hidden" aria-hidden="true" />
            </DropdownMenuTrigger>
            <DropdownMenuPortal>
                <DropdownMenuContent align="end" :side-offset="4" class="floating z-50">
                    <DropdownMenuRadioGroup v-model="language">
                        <DropdownMenuRadioItem value="auto" class="menu-item">
                            {{ t("bar.auto") }}
                            <DropdownMenuItemIndicator class="ms-auto ps-4"><Check class="size-4" aria-hidden="true" /></DropdownMenuItemIndicator>
                        </DropdownMenuRadioItem>
                        <DropdownMenuSeparator class="my-1.5 h-px bg-outline" />
                        <DropdownMenuRadioItem v-for="item in locales" :key="item.code" :value="item.code" class="menu-item" :lang="item.code">
                            {{ item.label }}
                            <DropdownMenuItemIndicator class="ms-auto ps-4"><Check class="size-4" aria-hidden="true" /></DropdownMenuItemIndicator>
                        </DropdownMenuRadioItem>
                    </DropdownMenuRadioGroup>
                </DropdownMenuContent>
            </DropdownMenuPortal>
        </DropdownMenuRoot>
        <a href="https://github.com/MindsMaster/spine-converter" :class="button.outline" class="ms-2 ps-3">
            <svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
                <path
                    d="M12 .5a11.5 11.5 0 0 0-3.64 22.41c.58.1.79-.25.79-.56v-2c-3.2.7-3.88-1.36-3.88-1.36-.52-1.33-1.28-1.68-1.28-1.68-1.04-.71.08-.7.08-.7 1.16.08 1.77 1.19 1.77 1.19 1.03 1.76 2.7 1.25 3.36.96.1-.75.4-1.25.73-1.54-2.55-.29-5.24-1.28-5.24-5.69 0-1.26.45-2.29 1.19-3.1-.12-.29-.52-1.46.11-3.05 0 0 .97-.31 3.17 1.18a11 11 0 0 1 5.77 0c2.2-1.49 3.17-1.18 3.17-1.18.63 1.59.23 2.76.11 3.05.74.81 1.19 1.84 1.19 3.1 0 4.42-2.7 5.4-5.26 5.68.41.36.78 1.06.78 2.14v3.17c0 .31.21.67.8.56A11.5 11.5 0 0 0 12 .5Z"
                    />
            </svg>
            <span class="max-sm:sr-only">{{ t("bar.repository") }}</span>
        </a>
    </header>
</template>
