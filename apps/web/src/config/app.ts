import type { ReadonlyDeep } from "type-fest";

import { type Chain } from "viem";

import { chain, chainId } from "@/config/chain";

export interface AppConfig {
  chain: Chain;
  chainId: number;
  subgraphUrl?: string;
}

function resolveSubgraphUrl(): string | undefined {
  const environment = import.meta.env as {
    VITE_SUBGRAPH_URL?: string;
  };
  return environment.VITE_SUBGRAPH_URL ?? undefined;
}

export const baseAppConfig: ReadonlyDeep<AppConfig> = {
  chain,
  chainId,
  subgraphUrl: resolveSubgraphUrl(),
};

// App-level config can extend/override base settings here if needed.
export const appConfig: ReadonlyDeep<AppConfig> = {
  ...baseAppConfig,
};
