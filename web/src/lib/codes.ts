import docZh from "../../../docs/report.zh-CN.md?raw";

const row = /^\| `([a-zA-Z0-9.]+)` \| \w+ \| \w+ \| (.+) \|$/gm;

/** Meanings come from the code table of docs/report.zh-CN.md */
export const meaningsZh: ReadonlyMap<string, string> = new Map(
    Array.from(docZh.matchAll(row), (match) => [match[1]!, match[2]!.replaceAll("`", "")]),
);
