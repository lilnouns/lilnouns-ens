import { createConfig, http } from "wagmi";
import { coinbaseWallet, injected, walletConnect } from "wagmi/connectors";

import { chain } from "@/config/chain";

const rpcHttpUrl = (import.meta.env as { VITE_RPC_HTTP_URL?: string }).VITE_RPC_HTTP_URL;

export const config = createConfig({
  chains: [chain],
  connectors: [
    injected(),
    coinbaseWallet(),
    walletConnect({ projectId: import.meta.env.VITE_WC_PROJECT_ID ?? "" }),
  ],
  transports: {
    [chain.id]: http(rpcHttpUrl && rpcHttpUrl.length > 0 ? rpcHttpUrl : undefined),
  },
});

declare module "wagmi" {
  interface Register {
    config: typeof config;
  }
}
