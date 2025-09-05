import {
  useReadLilNounsTokenBalanceOf,
  useReadLilNounsTokenTokenOfOwnerByIndex,
} from "@nekofar/lilnouns/contracts";

import { chainId } from "@/config/chain";

export interface UseOwnershipStateResult {
  balanceError: boolean;
  cannotClaim: boolean;
  firstTokenId?: bigint;
  firstTokenLoading: boolean;
  mustChooseToken: boolean;
  ownedCount: number;
  nounsError: boolean;
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

  const mustChooseToken = !!isConnected && ownedCount > 1;
  const cannotClaim = !!isConnected && ownedCount === 0;

  return {
    balanceError,
    cannotClaim,
    firstTokenId,
    firstTokenLoading,
    mustChooseToken,
    ownedCount,
    nounsError: false,
  } as const;
}
