import tailwindcss from "@tailwindcss/vite";
import react from "@vitejs/plugin-react";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { defineConfig } from "vite";

// https://vite.dev/config/
export default defineConfig({
  plugins: [react(), tailwindcss()],
  resolve: {
    alias: {
      "@": path.resolve(fileURLToPath(new URL("src", import.meta.url))),
      "@repo/ui": path.resolve(
        fileURLToPath(new URL("../../packages/ui/src", import.meta.url)),
      ),
    },
    // Ensure a single instance of these libs across the workspace (pnpm + Vite)
    dedupe: ["react", "react-dom", "wagmi", "viem", "@tanstack/react-query"],
  },
});
