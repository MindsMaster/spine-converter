import { ref } from "vue";

export type Scheme = "light" | "dark";
export type SchemePreference = Scheme | "system";

const storageKey = "color-scheme";
const system = matchMedia("(prefers-color-scheme: dark)");
const meta = document.querySelector<HTMLMetaElement>('meta[name="color-scheme"]')!;

const systemScheme = (): Scheme => (system.matches ? "dark" : "light");
const parse = (value: string | null): SchemePreference => (value === "light" || value === "dark" ? value : "system");

export const preference = ref<SchemePreference>(parse(meta.content));
export const scheme = ref<Scheme>(preference.value === "system" ? systemScheme() : preference.value);

system.addEventListener("change", () => preference.value === "system" && (scheme.value = systemScheme()));
window.addEventListener("storage", (event) => event.key === storageKey && apply(parse(event.newValue)));

function apply(value: SchemePreference): void {
    const update = () => {
        preference.value = value;
        meta.content = value === "system" ? "light dark" : value;
        scheme.value = value === "system" ? systemScheme() : value;
    };
    if (document.startViewTransition && !matchMedia("(prefers-reduced-motion: reduce)").matches) document.startViewTransition(update);
    else update();
}

export function setScheme(value: SchemePreference): void {
    try {
        if (value === "system") localStorage.removeItem(storageKey);
        else localStorage.setItem(storageKey, value);
    } catch {}
    apply(value);
}
