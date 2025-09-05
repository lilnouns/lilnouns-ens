import { farcasterMiniApp as miniAppConnector } from "@farcaster/miniapp-wagmi-connector";
import { createConfig, http } from "wagmi";
import { coinbaseWallet, injected, walletConnect } from "wagmi/connectors";

import { chain } from "@/config/chain";
import { getRpcHttpUrl, getWcProjectId } from "@/config/runtime-environment.ts";

const rpcHttpUrl = getRpcHttpUrl();
const wcProjectId = getWcProjectId();
const baseConnectors = [injected(), coinbaseWallet(), miniAppConnector()];
const connectors =
  wcProjectId && wcProjectId.length > 0
    ? [...baseConnectors, walletConnect({ projectId: wcProjectId })]
    : baseConnectors;

export const config = createConfig({
  chains: [chain],
  connectors,
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
