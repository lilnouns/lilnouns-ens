import { useQuery } from '@tanstack/react-query'

import { parseDataUriToJson, resolveUriToHttp } from '@/utils/resolve-uri'

// minimal ERC721 metadata shape
export interface NftAttribute { trait_type?: string; value?: unknown }
export interface NftMetadata {
  // keep index signature flexible for collection-specific fields
  [k: string]: unknown
  animation_url?: string
  attributes?: NftAttribute[]
  description?: string
  image?: string
  name?: string
}

export function useTokenMetadata(tokenUri: string | undefined) {
  return useQuery({
    enabled: !!tokenUri,
    queryFn: async (): Promise<NftMetadata> => {
      if (!tokenUri) return {}
      // data: URI inline JSON
      if (tokenUri.startsWith('data:')) {
        const data = parseDataUriToJson(tokenUri)
        return (data ?? {}) as NftMetadata
      }
      // http or ipfs
      const url = resolveUriToHttp(tokenUri)
      const data = await fetchJsonWithTimeout(url)
      return (data ?? {}) as NftMetadata
    },
    queryKey: ['token-metadata', tokenUri],
    staleTime: 60_000,
  })
}

async function fetchJsonWithTimeout(url: string, ms = 10_000): Promise<unknown> {
  const controller = new AbortController()
  const id = setTimeout(() => { controller.abort(); }, ms)
  try {
    const res = await fetch(url, { signal: controller.signal })
    if (!res.ok) throw new Error(`http ${res.status}`)
    return await res.json()
  } finally {
    clearTimeout(id)
  }
}
