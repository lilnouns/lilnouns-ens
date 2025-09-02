import { type Chain } from 'viem'

import { chain, chainId } from '@/config/chain'

export interface AppConfig {
  chain: Chain
  chainId: number
  subgraphUrl?: string
}

function resolveSubgraphUrl(selectedChainId: number): string | undefined {
  const env = import.meta.env as {
    VITE_SUBGRAPH_URL?: string
    VITE_SUBGRAPH_URL_MAINNET?: string
    VITE_SUBGRAPH_URL_SEPOLIA?: string
  }

  // Use chain-specific URLs only to ensure data comes from the configured chain.
  if (selectedChainId === 11155111) return env.VITE_SUBGRAPH_URL_SEPOLIA || undefined
  if (selectedChainId === 1) return env.VITE_SUBGRAPH_URL_MAINNET || undefined

  // Do not fall back to the generic URL to avoid cross-network mismatches.
  return undefined
}

export const baseAppConfig: AppConfig = {
  chain,
  chainId,
  subgraphUrl: resolveSubgraphUrl(chainId),
}

// App-level config can extend/override base settings here if needed.
export const appConfig: AppConfig = {
  ...baseAppConfig,
}
