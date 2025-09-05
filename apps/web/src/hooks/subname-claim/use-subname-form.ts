import { useCallback, useMemo, useState } from "react";

import { chainId, chain as configuredChain } from "@/config/chain";

export interface UseSubnameFormParameters {
  balanceError: boolean;
  chainIdCurrent?: number;
  isConnected: boolean;
  mustChooseToken: boolean;
  nounsError: boolean;
  ownedCount: number;
}

export interface UseSubnameFormResult {
  setSubname: (v: string) => void;
  setSubnameError: (error?: string) => void;
  subname: string;
  subnameDisabledReason?: string;
  subnameError?: string;
  validateSubname: (value: string) => string | undefined;
}

export function useSubnameForm(
  parameters: UseSubnameFormParameters,
): UseSubnameFormResult {
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

