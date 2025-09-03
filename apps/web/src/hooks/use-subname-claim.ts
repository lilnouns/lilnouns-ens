import { useReadLilNounsTokenBalanceOf, useReadLilNounsTokenTokenOfOwnerByIndex } from "@nekofar/lilnouns/contracts";
import { useQuery } from "@tanstack/react-query";
import { useCallback, useMemo, useRef, useState } from "react";
import { useAccount, useWaitForTransactionReceipt } from "wagmi";

import type { OwnedNft } from "@/lib/types";

import { chainId, chain as configuredChain } from "@/config/chain";
import { useWriteLilNounsEnsMapperClaimSubname } from "@/hooks/contracts";
import { fetchOwnedLilNouns } from "@/lib/subgraph-client";

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

  txSuccess: boolean;
  txHash?: `0x${string}`;
  // validation + disabled reason
  validateSubname: (value: string) => string | undefined;
  writeErrorMessage?: string;
};

export function useSubnameClaim(toast?: (options: { description: string; title: string; variant?: "destructive" }) => void): UseSubnameClaimResult {
  const { address, chain, isConnected } = useAccount();
  const [isRegistered, setIsRegistered] = useState(false);
  const [subname, setSubname] = useState("");
  const [subnameError, setSubnameError] = useState<string | undefined>();

  const { data: balance, isError: balanceError, isLoading: balanceLoading } = useReadLilNounsTokenBalanceOf({
    args: address ? [address] : undefined,
    chainId,
    query: { enabled: isConnected && !!address },
  });
  const ownedCount = Number(balance ?? 0n);

  const { data: firstTokenId, isLoading: firstTokenLoading } = useReadLilNounsTokenTokenOfOwnerByIndex({
    args: address ? [address, 0n] : undefined,
    chainId,
    query: { enabled: isConnected && !!address && ownedCount === 1 },
  });

  const { data: nouns, isError: nounsError, isLoading: nounsLoading } = useQuery<OwnedNft[]>({
    enabled: isConnected && !!address && ownedCount > 1,
    queryFn: () => fetchOwnedLilNouns(address),
    queryKey: ["ownedLilNouns", address],
  });

  const { data: txHash, error: writeError, isPending: isWriting, writeContract } = useWriteLilNounsEnsMapperClaimSubname();
  const { isError: txError, isLoading: txPending, isSuccess: txSuccess } = useWaitForTransactionReceipt({
    chainId,
    hash: txHash,
    query: { enabled: !!txHash },
  });

  const mustChooseToken = isConnected && ownedCount > 1;
  const cannotClaim = isConnected && ownedCount === 0;

  const validateSubname = useCallback((value: string): string | undefined => {
    if (value.length < 3) return "Must be at least 3 characters";
    if (value.length > 63) return "Must be at most 63 characters";
    if (!/^[a-z0-9-]+$/.test(value)) return "Only lowercase letters, digits, and hyphens";
    if (!/^[a-z0-9]/.test(value)) return "Must start with a letter or digit";
    if (!/[a-z0-9]$/.test(value)) return "Must end with a letter or digit";
    return undefined;
  }, []);

  const claim = useCallback(
    (tokenId: bigint) => {
      if (!address) return;
      try {
        writeContract({ args: [subname, tokenId] });
      } catch {
        toast?.({ description: "Could not submit transaction.", title: "Transaction error", variant: "destructive" });
      }
    },
    [address, subname, writeContract, toast],
  );

  const subnameDisabledReason = useMemo(() => {
    if (!isConnected) return "Connect your wallet to proceed";
    if (chain?.id !== chainId) return `Wrong network. Please switch to ${configuredChain.name}.`;
    if (balanceError) return "Error loading Lil Nouns";
    if (mustChooseToken && nounsError) return "Error loading Lil Nouns";
    if (cannotClaim) return "You do not have a Lil Noun";
    return;
  }, [isConnected, chain?.id, balanceError, mustChooseToken, nounsError, cannotClaim]);

  const pending = isWriting || txPending;
  const hasError = !!writeError || txError;

  const announced = useRef(false);
  if (txSuccess && !announced.current) {
    announced.current = true;
    setIsRegistered(true);
    toast?.({ description: "Subname claimed successfully!", title: "Success" });
  }
  if (hasError && !announced.current) {
    announced.current = true;
    toast?.({ description: "Please check your wallet or try again.", title: "Transaction failed", variant: "destructive" });
  }

  return {
    cannotClaim,
    claim,
    firstTokenId,
    firstTokenLoading,
    hasError,
    isRegistered,
    mustChooseToken,
    nouns,
    nounsError: !!nounsError,
    nounsLoading,
    ownedCount,
    pending,
    setSubname,
    setSubnameError,
    subname,
    subnameDisabledReason,
    subnameError,
    txSuccess,
    txHash,
    validateSubname,
    writeErrorMessage: writeError ? String(writeError.message ?? writeError) : undefined,
  };
}
