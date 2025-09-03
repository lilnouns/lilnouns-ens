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
): { note?: string; blocksCta: boolean } {
  const { data: simOk, error: simError, isLoading: simLoading } =
    useSimulateLilNounsEnsMapperClaimSubname({
      args: enabled && tokenId ? [subname, tokenId] : undefined,
      chainId,
      query: { enabled: enabled && !!tokenId && !!subname, staleTime: 15_000 },
    });

  return useMemo(() => {
    if (simLoading) return { note: "Checking availability…", blocksCta: false } as const;
    if (simError) {
      const msg = String((simError as Error)?.message || simError);
      if (msg.includes("AlreadyClaimed")) return { note: "That subname is already claimed. Try another.", blocksCta: true } as const;
      if (msg.includes("InvalidLabel")) return { note: "Invalid subname. Use a–z, 0–9, hyphen; 3–63 chars.", blocksCta: true } as const;
      if (msg.includes("PreexistingENSRecord")) return { note: "This label collides with an existing ENS record.", blocksCta: true } as const;
      if (msg.includes("NotTokenOwner") || msg.includes("NotAuthorised")) return { note: "You must claim with the owner of the selected Lil Noun.", blocksCta: true } as const;
      if (msg.includes("UnregisteredNode")) return { note: "The root ENS node is not registered yet.", blocksCta: true } as const;
      return { note: "Cannot claim this subname. Please try another or retry.", blocksCta: true } as const;
    }
    if (simOk) return { note: "Available", blocksCta: false } as const;
    return { note: undefined, blocksCta: false } as const;
  }, [simLoading, simError, simOk]);
}

