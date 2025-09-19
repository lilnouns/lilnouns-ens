import { useWriteLilNounsEnsMapperClaimSubname } from "@nekofar/lilnouns/contracts";
import { useCallback, useRef, useState } from "react";
import { useWaitForTransactionReceipt } from "wagmi";

import { chainId } from "@/config/chain";

export interface UseClaimTxParameters {
  address?: `0x${string}`;
  subname: string;
  toast?: (options: {
    description: string;
    title: string;
    variant?: "destructive";
  }) => void;
}

export interface UseClaimTxResult {
  claim: (tokenId: bigint) => void;
  hasError: boolean;
  isRegistered: boolean;
  pending: boolean;
  txHash?: `0x${string}`;
  txSuccess: boolean;
  writeErrorMessage?: string;
}

export function useClaimTx(parameters: UseClaimTxParameters): UseClaimTxResult {
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

