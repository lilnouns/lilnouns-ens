import { type Chain } from 'viem'

import { chain, chainId } from '@/config/chain'

export interface AppConfig {
  chain: Chain
  chainId: number
  subgraphUrl?: string
}

export const baseAppConfig: AppConfig = {
  chain,
  chainId,
  subgraphUrl: import.meta.env.VITE_SUBGRAPH_URL,
}

// App-level config can extend/override base settings here if needed.
export const appConfig: AppConfig = {
  ...baseAppConfig,
}

