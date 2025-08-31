import tailwindcss from "@tailwindcss/vite";
import react from "@vitejs/plugin-react";
import path from "node:path";
import { defineConfig } from "vite";

// https://vite.dev/config/
export default defineConfig({
  plugins: [react(), tailwindcss()],
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
      "@repo/ui": path.resolve(__dirname, "../../packages/ui/src"),
    },
    // Ensure a single instance of these libs across the workspace (pnpm + Vite)
    dedupe: [
      "react",
      "react-dom",
      "wagmi",
      "viem",
      "@tanstack/react-query",
    ],
  },
});
