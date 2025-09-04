import {
  useReadLilNounsTokenBalanceOf,
  useReadLilNounsTokenTokenOfOwnerByIndex,
} from "@nekofar/lilnouns/contracts";
import { useQuery } from "@tanstack/react-query";
import { isTruthy } from "remeda";

import type { OwnedNft } from "@/lib/types";

import { chainId } from "@/config/chain";
import { fetchOwnedLilNouns } from "@/lib/subgraph-client";

export interface UseOwnershipStateResult {
  balanceError: boolean;
  cannotClaim: boolean;
  firstTokenId?: bigint;
  firstTokenLoading: boolean;
  mustChooseToken: boolean;
  nouns?: OwnedNft[];
  nounsError: boolean;
  nounsLoading: boolean;
  ownedCount: number;
}

export function useOwnershipState(
  address?: `0x${string}`,
  isConnected?: boolean,
): UseOwnershipStateResult {
  const { data: balance, isError: balanceError } =
    useReadLilNounsTokenBalanceOf({
      args: address ? [address] : undefined,
      chainId,
      query: { enabled: !!isConnected && !!address },
    });
  const ownedCount = Number(balance ?? 0n);

  const { data: firstTokenId, isLoading: firstTokenLoading } =
    useReadLilNounsTokenTokenOfOwnerByIndex({
      args: address ? [address, 0n] : undefined,
      chainId,
      query: { enabled: !!isConnected && !!address && ownedCount === 1 },
    });

  const {
    data: nouns,
    isError: nounsError,
    isLoading: nounsLoading,
  } = useQuery<OwnedNft[]>({
    enabled: !!isConnected && !!address && ownedCount > 1,
    queryFn: () => fetchOwnedLilNouns(address),
    queryKey: ["ownedLilNouns", address],
  });

  const mustChooseToken = !!isConnected && ownedCount > 1;
  const cannotClaim = !!isConnected && ownedCount === 0;

  return {
    balanceError,
    cannotClaim,
    firstTokenId,
    firstTokenLoading,
    mustChooseToken,
    nouns,
    nounsError: isTruthy(nounsError),
    nounsLoading,
    ownedCount,
  } as const;
}

