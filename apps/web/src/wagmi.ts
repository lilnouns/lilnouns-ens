import { createConfig, http } from "wagmi";
import { coinbaseWallet, injected, walletConnect } from "wagmi/connectors";

import { chain } from "@/config/chain";

function resolveRpcHttpUrl(): string | undefined {
  const environment = import.meta.env as {
    VITE_RPC_HTTP_URL?: string;
  };
  return environment.VITE_RPC_HTTP_URL ?? undefined;
}

const rpcHttpUrl = resolveRpcHttpUrl();

export const config = createConfig({
  chains: [chain],
  connectors: [
    injected(),
    coinbaseWallet(),
    walletConnect({ projectId: import.meta.env.VITE_WC_PROJECT_ID ?? "" }),
  ],
  transports: {
    // If no RPC URL is provided, viem will use defaults.
    [chain.id]: http(
      rpcHttpUrl && rpcHttpUrl.length > 0 ? rpcHttpUrl : undefined,
    ),
  },
});

declare module "wagmi" {
  interface Register {
    config: typeof config;
  }
}
