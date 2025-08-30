import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { WagmiProvider } from "wagmi";

import { ThemeProvider } from "@/components/theme-provider";
import { ToastProvider } from "@/components/toast";

import App from "./app.tsx";
import { config } from "./wagmi.ts";

import "@repo/ui/index.css";

const queryClient = new QueryClient();

const rootElement = document.querySelector("#root");
if (!rootElement) {
  throw new Error("Root element not found");
}
createRoot(rootElement).render(
  <StrictMode>
    <ThemeProvider>
      <WagmiProvider config={config}>
        <QueryClientProvider client={queryClient}>
          <ToastProvider>
            <App />
          </ToastProvider>
        </QueryClientProvider>
      </WagmiProvider>
    </ThemeProvider>
  </StrictMode>,
);
