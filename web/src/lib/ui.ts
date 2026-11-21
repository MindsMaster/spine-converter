const base =
    "inline-flex h-9 shrink-0 items-center justify-center gap-2 rounded-full font-medium whitespace-nowrap transition-colors duration-100 disabled:cursor-not-allowed disabled:opacity-45 [&_svg]:size-5";

export const button = {
    filled: `${base} bg-primary px-4 text-on-primary enabled:hover:bg-primary-hover`,
    tonal: `${base} bg-tonal px-4 text-on-tonal enabled:hover:bg-tonal-hover`,
    outline: `${base} border border-ctl px-4 enabled:hover:bg-hover`,
    text: `${base} px-3 enabled:hover:bg-hover`,
    icon: `${base} size-9 text-ink-2 enabled:hover:bg-hover enabled:hover:text-ink`,
    iconSmall: `${base} size-8 text-ink-2 enabled:hover:bg-hover enabled:hover:text-ink pointer-coarse:size-10 [&_svg]:size-[1.125rem]`,
};
