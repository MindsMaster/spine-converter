export function formatSize(bytes: number, locale: string): string {
    if (bytes < 1024) return `${bytes}\u00a0B`;
    const [value, unit] = bytes >= 1024 * 1024 ? [bytes / 1024 / 1024, "MB"] : [bytes / 1024, "KB"];
    return `${new Intl.NumberFormat(locale, { maximumFractionDigits: 1 }).format(value)} ${unit}`;
}
