import { useMemo } from "react";

import { chainId } from "@/config/chain";
import { useSimulateLilNounsEnsMapperClaimSubname } from "@/hooks/contracts";

/**
 * useClaimAvailability
 * Runs a contract simulate for claimSubname and returns a user-facing note
 * plus a boolean that indicates whether the CTA should be blocked.
 */
export function useClaimAvailability(
  enabled: boolean,
  subname: string,
  tokenId: bigint | undefined,
): { blocksCta: boolean; note?: string } {
  const {
    data: simOk,
    error: simError,
    isLoading: simLoading,
  } = useSimulateLilNounsEnsMapperClaimSubname({
    args: enabled && tokenId ? [subname, tokenId] : [undefined],
    chainId,
    query: { enabled: enabled && !!tokenId && !!subname, staleTime: 15_000 },
  });

  return useMemo(() => {
    if (simLoading)
      return { blocksCta: false, note: "Checking availability…" } as const;
    if (simError) {
      const message = String((simError as Error)?.message || simError);
      if (message.includes("AlreadyClaimed"))
        return {
          blocksCta: true,
          note: "That subname is already claimed. Try another.",
        } as const;
      if (message.includes("InvalidLabel"))
        return {
          blocksCta: true,
          note: "Invalid subname. Use a–z, 0–9, hyphen; 3–63 chars.",
        } as const;
      if (message.includes("PreexistingENSRecord"))
        return {
          blocksCta: true,
          note: "This label collides with an existing ENS record.",
        } as const;
      if (
        message.includes("NotTokenOwner") ||
        message.includes("NotAuthorised")
      )
        return {
          blocksCta: true,
          note: "You must claim with the owner of the selected Lil Noun.",
        } as const;
      if (message.includes("UnregisteredNode"))
        return {
          blocksCta: true,
          note: "The root ENS node is not registered yet.",
        } as const;
      return {
        blocksCta: true,
        note: "Cannot claim this subname. Please try another or retry.",
      } as const;
    }
    if (simOk) return { blocksCta: false, note: "Available" } as const;
    return { blocksCta: false, note: undefined } as const;
  }, [simLoading, simError, simOk]);
}
