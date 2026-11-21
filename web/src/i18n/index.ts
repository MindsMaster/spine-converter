import { ref, watchEffect } from "vue";
import { createI18n } from "vue-i18n";
import en from "./en";
import zh from "./zh-CN";

export const locales = [
    { code: "zh-CN", label: "简体中文" },
    { code: "en", label: "English" },
] as const;
export type Locale = (typeof locales)[number]["code"];
export type LocalePreference = Locale | "auto";

const storageKey = "spc-locale";

const browserLocale = (): Locale => (navigator.languages.some((tag) => tag.toLowerCase().startsWith("zh")) ? "zh-CN" : "en");

function stored(): LocalePreference {
    try {
        const value = localStorage.getItem(storageKey);
        if (value === "zh-CN" || value === "en") return value;
    } catch {}
    return "auto";
}

export const localePreference = ref<LocalePreference>(stored());

export const i18n = createI18n({
    legacy: false,
    locale: localePreference.value === "auto" ? browserLocale() : localePreference.value,
    fallbackLocale: "en",
    messages: { "zh-CN": zh, en },
});

watchEffect(() => (document.documentElement.lang = i18n.global.locale.value));
addEventListener("languagechange", () => localePreference.value === "auto" && (i18n.global.locale.value = browserLocale()));

export function setLocale(value: LocalePreference): void {
    localePreference.value = value;
    i18n.global.locale.value = value === "auto" ? browserLocale() : value;
    try {
        if (value === "auto") localStorage.removeItem(storageKey);
        else localStorage.setItem(storageKey, value);
    } catch {}
}
