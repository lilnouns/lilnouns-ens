import type { ReadonlyDeep } from "type-fest";

import { type Chain } from "viem";

import { chain, chainId } from "@/config/chain";
import { getSubgraphUrl } from "@/config/runtime-environment";

export interface AppConfig {
  chain: Chain;
  chainId: number;
  subgraphUrl?: string;
}

export const baseAppConfig: ReadonlyDeep<AppConfig> = {
  chain,
  chainId,
  subgraphUrl: getSubgraphUrl(),
};

// App-level config can extend/override base settings here if needed.
export const appConfig: ReadonlyDeep<AppConfig> = {
  ...baseAppConfig,
};
