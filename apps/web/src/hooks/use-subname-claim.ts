import {
  useReadLilNounsTokenBalanceOf,
  useReadLilNounsTokenTokenOfOwnerByIndex,
} from "@nekofar/lilnouns/contracts";
import { useQuery } from "@tanstack/react-query";
import { useCallback, useMemo, useRef, useState } from "react";
import { isTruthy } from "remeda";
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

function useClaimTx(parameters: {
  address?: `0x${string}`;
  subname: string;
  toast?: (options: {
    description: string;
    title: string;
    variant?: "destructive";
  }) => void;
}) {
  const { address, subname, toast } = parameters;
  const [isRegistered, setIsRegistered] = useState(false);
  const {
    data: txHash,
    error: writeError,
    isPending: isWriting,
    writeContract,
  } = useWriteLilNounsEnsMapperClaimSubname();
  const {
    isError: txError,
    isLoading: txPending,
    isSuccess: txSuccess,
  } = useWaitForTransactionReceipt({
    chainId,
    hash: txHash,
    query: { enabled: !!txHash },
  });

  const claim = useCallback(
    (tokenId: bigint) => {
      if (!address) return;
      try {
        writeContract({ args: [subname, tokenId] });
      } catch {
        toast?.({
          description: "Could not submit transaction.",
          title: "Transaction error",
          variant: "destructive",
        });
      }
    },
    [address, subname, writeContract, toast],
  );

  const pending = isWriting || txPending;
  const hasError = !!writeError || txError;
  const writeErrorMessage = writeError
    ? ((writeError.message ?? writeError) satisfies string)
    : undefined;

  const announced = useRef(false);
  if (txSuccess && !announced.current) {
    announced.current = true;
    setIsRegistered(true);
    toast?.({ description: "Subname claimed successfully!", title: "Success" });
  }
  if (hasError && !announced.current) {
    announced.current = true;
    toast?.({
      description: "Please check your wallet or try again.",
      title: "Transaction failed",
      variant: "destructive",
    });
  }

  return {
    claim,
    hasError,
    isRegistered,
    pending,
    txHash,
    txSuccess,
    writeErrorMessage,
  } as const;
}

function useOwnershipState(address?: `0x${string}`, isConnected?: boolean) {
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

// ========================= Facade hook (public API unchanged) =========================

function useSubnameForm(parameters: {
  balanceError: boolean;
  chainIdCurrent?: number;
  isConnected: boolean;
  mustChooseToken: boolean;
  nounsError: boolean;
  ownedCount: number;
}) {
  const {
    balanceError,
    chainIdCurrent,
    isConnected,
    mustChooseToken,
    nounsError,
    ownedCount,
  } = parameters;
  const [subname, setSubname] = useState("");
  const [subnameError, setSubnameError] = useState<string | undefined>();

  const validateSubname = useCallback((value: string): string | undefined => {
    if (value.length < 3) return "Must be at least 3 characters";
    if (value.length > 63) return "Must be at most 63 characters";
    if (!/^[a-z0-9-]+$/.test(value))
      return "Only lowercase letters, digits, and hyphens";
    if (!/^[a-z0-9]/.test(value)) return "Must start with a letter or digit";
    if (!/[a-z0-9]$/.test(value)) return "Must end with a letter or digit";
    return undefined;
  }, []);

  const subnameDisabledReason = useMemo(() => {
    if (!isConnected) return "Connect your wallet to proceed";
    if (chainIdCurrent !== chainId)
      return `Wrong network. Please switch to ${configuredChain.name}.`;
    if (balanceError) return "Error loading Lil Nouns";
    if (mustChooseToken && nounsError) return "Error loading Lil Nouns";
    if (isConnected && ownedCount === 0) return "You do not have a Lil Noun";
    return;
  }, [
    isConnected,
    chainIdCurrent,
    balanceError,
    mustChooseToken,
    nounsError,
    ownedCount,
  ]);

  return {
    setSubname,
    setSubnameError,
    subname,
    subnameDisabledReason,
    subnameError,
    validateSubname,
  } as const;
}
