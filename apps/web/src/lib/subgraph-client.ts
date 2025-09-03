import type { Query } from "@nekofar/lilnouns/subgraphs";
import type { Address } from "viem";

import { gql, GraphQLClient } from "graphql-request";
import { pipe, map } from "remeda";

import type { OwnedNft } from "@/lib/types.ts";

import { appConfig } from "@/config/app.ts";

const placeholderImageURL = "https://placehold.co/512x512/png?text=Lil+Noun";

export async function fetchOwnedLilNouns(
  address: Address | undefined,
): Promise<OwnedNft[]> {
  if (!address) return [];
  if (!appConfig.subgraphUrl) return mockOwned(address);
  try {
    const client = new GraphQLClient(appConfig.subgraphUrl);

    const data = await client.request<Query>(
      gql`
        query Nouns($owner: String!) {
          nouns(where: { owner: $owner }) {
            id
          }
        }
      `,
      {
        owner: address.toLowerCase(),
      },
    );

    return pipe(
      data.nouns,
      map((t) => ({
        image: /*t.image ??*/ placeholderImageURL,
        name: /*t.name ??*/ `Lil Noun #${t.id}`,
        tokenId: t.id,
      })),
    );
  } catch {
    return mockOwned(address);
  }
}

function mockOwned(address: string): OwnedNft[] {
  const last = Number.parseInt(address.slice(-2), 16);
  const count = last % 3; // 0,1,2 deterministic
  return pipe(
    Array.from({ length: count }, (_, index) => index),
    map((index) => {
      const id = (1000 + index).toString();
      return {
        image: `${placeholderImageURL}&token=${id}`,
        name: `Lil Noun #${id}`,
        tokenId: id,
      } satisfies OwnedNft;
    }),
  );
}
