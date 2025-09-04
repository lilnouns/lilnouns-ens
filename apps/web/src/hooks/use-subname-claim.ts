import { isTruthy } from "remeda";
import { useAccount } from "wagmi";

import type { OwnedNft } from "@/lib/types";

import { useClaimTx } from "@/hooks/subname-claim/use-claim-tx";
import { useOwnershipState } from "@/hooks/subname-claim/use-ownership-state";
import { useSubnameForm } from "@/hooks/subname-claim/use-subname-form";

export interface UseSubnameClaimResult {
  cannotClaim: boolean;
  claim: (tokenId: bigint) => void;
  firstTokenId?: bigint;
  firstTokenLoading: boolean;

  hasError: boolean;
  isRegistered: boolean;
  mustChooseToken: boolean;
  nouns?: OwnedNft[];
  nounsError: boolean;
  nounsLoading: boolean;
  // ownership and selection
  ownedCount: number;
  // tx state
  pending: boolean;

  setSubname: (v: string) => void;
  // actions
  setSubnameError: (error?: string) => void;
  // state
  subname: string;

  subnameDisabledReason?: string;
  subnameError?: string;

  txHash?: `0x${string}`;
  txSuccess: boolean;
  // validation + disabled reason
  validateSubname: (value: string) => string | undefined;
  writeErrorMessage?: string;
}

// ========================= Internal hooks =========================

export function useSubnameClaim(
  toast?: (options: {
    description: string;
    title: string;
    variant?: "destructive";
  }) => void,
): UseSubnameClaimResult {
  const { address, chain, isConnected } = useAccount();

  const ownership = useOwnershipState(address, isConnected);
  const form = useSubnameForm({
    balanceError: ownership.balanceError,
    chainIdCurrent: chain?.id,
    isConnected: isTruthy(isConnected),
    mustChooseToken: ownership.mustChooseToken,
    nounsError: ownership.nounsError,
    ownedCount: ownership.ownedCount,
  });
  const tx = useClaimTx({ address, subname: form.subname, toast });

  return {
    cannotClaim: ownership.cannotClaim,
    claim: tx.claim,
    firstTokenId: ownership.firstTokenId,
    firstTokenLoading: ownership.firstTokenLoading,
    hasError: tx.hasError,
    isRegistered: tx.isRegistered,
    mustChooseToken: ownership.mustChooseToken,
    nouns: ownership.nouns,
    nounsError: ownership.nounsError,
    nounsLoading: ownership.nounsLoading,
    ownedCount: ownership.ownedCount,
    pending: tx.pending,
    setSubname: form.setSubname,
    setSubnameError: form.setSubnameError,
    subname: form.subname,
    subnameDisabledReason: form.subnameDisabledReason,
    subnameError: form.subnameError,
    txHash: tx.txHash,
    txSuccess: tx.txSuccess,
    validateSubname: form.validateSubname,
    writeErrorMessage: tx.writeErrorMessage,
  };
}
