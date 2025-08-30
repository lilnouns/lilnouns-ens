import type { OwnedNft } from "./types";

type TokensResponse = {
  data?: { tokens: Array<{ id: string; tokenId: string; image?: string | null; name?: string | null }> };
  errors?: Array<{ message: string }>;
};

const DEFAULT_IMAGE = "https://placehold.co/512x512/png?text=Lil+Noun";

const QUERY = `
  query Tokens($owner: String!) {
    tokens(where: { owner: $owner }) {
      id
      tokenId
      image
      name
    }
  }
`;

const SUBGRAPH_URL = import.meta.env.VITE_SUBGRAPH_URL as string | undefined;

export async function fetchOwnedLilNouns(address: `0x${string}`): Promise<OwnedNft[]> {
  if (!SUBGRAPH_URL) return mockOwned(address);
  try {
    const res = await fetch(SUBGRAPH_URL, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ query: QUERY, variables: { owner: address.toLowerCase() } }),
    });
    const json = (await res.json()) as TokensResponse;
    if (json.errors) return mockOwned(address);
    const items = json.data?.tokens ?? [];
    return items.map((t) => ({ tokenId: t.tokenId, image: t.image ?? DEFAULT_IMAGE, name: t.name ?? `Lil Noun #${t.tokenId}` }));
  } catch {
    return mockOwned(address);
  }
}

function mockOwned(address: string): OwnedNft[] {
  const last = parseInt(address.slice(-2), 16);
  const count = last % 3; // 0,1,2 deterministic
  const arr: OwnedNft[] = [];
  for (let i = 0; i < count; i++) {
    const id = (1000 + i).toString();
    arr.push({ tokenId: id, image: `${DEFAULT_IMAGE}&token=${id}`, name: `Lil Noun #${id}` });
  }
  return arr;
}

