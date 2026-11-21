import { fileURLToPath } from "node:url";
import tailwindcss from "@tailwindcss/vite";
import vue from "@vitejs/plugin-vue";
import { defineConfig } from "vite";

export default defineConfig({
    base: "./",
    plugins: [vue(), tailwindcss()],
    server: {
        fs: { allow: [fileURLToPath(new URL("..", import.meta.url))] },
    },
    worker: { format: "es" },
    build: { target: "baseline-widely-available" },
});
