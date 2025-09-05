import { createConfig, http } from "wagmi";
import { coinbaseWallet, injected, walletConnect } from "wagmi/connectors";

import { chain } from "@/config/chain";

function resolveRpcHttpUrl(selectedChainId: number): string | undefined {
  const environment = import.meta.env as {
    VITE_RPC_HTTP_URL?: string
    VITE_RPC_HTTP_URL_MAINNET?: string
    VITE_RPC_HTTP_URL_SEPOLIA?: string
  };

  // Use chain-specific variables only to avoid cross-network mix-ups.
  if (selectedChainId === 1) return environment.VITE_RPC_HTTP_URL_MAINNET ?? undefined;
  if (selectedChainId === 11_155_111) return environment.VITE_RPC_HTTP_URL_SEPOLIA ?? undefined;
  return undefined;
}

const rpcHttpUrl = resolveRpcHttpUrl(chain.id);

export const config = createConfig({
  chains: [chain],
  connectors: [
    injected(),
    coinbaseWallet(),
    walletConnect({ projectId: import.meta.env.VITE_WC_PROJECT_ID ?? "" }),
  ],
  transports: {
    // If no RPC URL is provided for the selected chain, vim will use defaults.
    [chain.id]: http(rpcHttpUrl && rpcHttpUrl.length > 0 ? rpcHttpUrl : undefined),
  },
});

declare module "wagmi" {
  interface Register {
    config: typeof config;
  }
}
