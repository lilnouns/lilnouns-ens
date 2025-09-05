import tailwindcss from "@tailwindcss/vite";
import react from "@vitejs/plugin-react";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { defineConfig, loadEnv } from "vite";

// https://vite.dev/config/
export default defineConfig(({ mode }) => {
  // Ensure env files like .env.production.local are loaded before reading VITE_BASE_PATH
  const environment = loadEnv(mode, process.cwd(), "");

  return {
    // Use environment variable to set base path for assets and routing
    base: environment.VITE_BASE_PATH || "/",
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
    // Run dev server on port 3000
    server: {
      port: 3000,
    },
  };
});
