import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { WagmiProvider } from "wagmi";

import { ThemeProvider } from "@/components/theme-provider";

import App from "./app.tsx";
import { config } from "./wagmi.ts";

import "@repo/ui/index.css";

const queryClient = new QueryClient();

createRoot(document.querySelector("#root")!).render(
  <StrictMode>
    <ThemeProvider>
      <WagmiProvider config={config}>
        <QueryClientProvider client={queryClient}>
          <App />
        </QueryClientProvider>
      </WagmiProvider>
    </ThemeProvider>
  </StrictMode>,
);
