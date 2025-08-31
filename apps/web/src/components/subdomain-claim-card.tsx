import { Button } from "@repo/ui/components/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@repo/ui/components/card";
import { Separator } from "@repo/ui/components/separator";
import { useQuery } from "@tanstack/react-query";
import { useCallback, useMemo, useRef, useState } from "react";
import { useAccount, useWaitForTransactionReceipt } from "wagmi";

import type { OwnedNft } from "@/lib/types";

import { NftGalleryDialog } from "@/components/nft-gallery-dialog";
import { useToast } from "@/components/toast";
import { useWriteLilNounsEnsMapperClaimSubname } from "@/hooks/contracts";
import { fetchOwnedLilNouns } from "@/lib/subgraph-client";
import { shortenAddress } from "@/utils/address";

// Address provided via generated hooks; no local constant needed.

export function SubdomainClaimCard() {
  const { toast } = useToast();
  const { address, chain, isConnected } = useAccount();
  const [isRegistered, setIsRegistered] = useState(false);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [selectedTokenId, setSelectedTokenId] = useState<string | undefined>();
  const [subdomain, setSubdomain] = useState("");

  const { data: nouns, isError: nounsError, isLoading: nounsLoading } = useQuery<OwnedNft[]>({
    enabled: isConnected && !!address,
    queryFn: () => fetchOwnedLilNouns(address!),
    queryKey: ["ownedLilNouns", address],
  });

  const ownedCount = nouns?.length ?? 0;

  const { data: txHash, error: writeError, isPending: isWriting, writeContract } =
    useWriteLilNounsEnsMapperClaimSubname();
  const { isError: txError, isLoading: txPending, isSuccess: txSuccess } = useWaitForTransactionReceipt({
    hash: txHash,
    query: { enabled: !!txHash },
  });

  // const canClaimDirectly = isConnected && ownedCount === 1;
  const mustChooseToken = isConnected && ownedCount > 1;
  const cannotClaim = isConnected && ownedCount === 0;

  const validateSubdomain = useCallback((value: string): string | undefined => {
    if (value.length < 3) return "Must be at least 3 characters";
    if (value.length > 63) return "Must be at most 63 characters";
    if (!/^[a-z0-9-]+$/.test(value)) return "Only lowercase letters, digits, and hyphens";
    if (!/^[a-z0-9]/.test(value)) return "Must start with a letter or digit";
    if (!/[a-z0-9]$/.test(value)) return "Must end with a letter or digit";
    return undefined;
  }, []);

  const [subdomainError, setSubdomainError] = useState<string | undefined>();

  const claim = useCallback(
    (tokenId: bigint) => {
      if (!address) return;
      try {
        writeContract({ args: [subdomain, tokenId] });
      } catch {
        toast({ description: "Could not submit transaction.", title: "Transaction error", variant: "destructive" });
      }
    },
    [address, subdomain, toast, writeContract],
  );

  const onSubmit = useCallback(() => {
    const error = validateSubdomain(subdomain);
    setSubdomainError(error);
    if (error) {
      toast({ description: error, title: "Invalid subname", variant: "destructive" });
      return;
    }
    if (!isConnected) {
      toast({ description: "Please connect your wallet first.", title: "Connect wallet" });
      return;
    }
    if (ownedCount === 0) {
      toast({
        description: "You must own at least one Lil Noun to claim.",
        title: "No Lil Nouns found",
        variant: "destructive",
      });
      return;
    }
    if (ownedCount === 1 && nouns?.[0]) {
      claim(BigInt(nouns[0].tokenId));
      return;
    }
    if (ownedCount > 1) {
      setDialogOpen(true);
      return;
    }
    toast({ description: "Unknown state; please try again.", title: "Unable to proceed" });
  }, [validateSubdomain, subdomain, isConnected, ownedCount, nouns, claim, toast]);

  const onTokenSelect = useCallback(
    (tokenId: string) => {
      setSelectedTokenId(tokenId);
      setDialogOpen(false);
      claim(BigInt(tokenId));
    },
    [claim],
  );

  const subdomainDisabledReason = useMemo(() => {
    if (!isConnected) return "Connect your wallet to proceed";
    if (nounsLoading) return "Loading your Lil Nouns…";
    if (nounsError) return "Error loading Lil Nouns";
    if (cannotClaim) return "You do not have a Lil Noun";
    return;
  }, [isConnected, nounsLoading, nounsError, cannotClaim]);

  const pending = isWriting || txPending;
  const hasError = !!writeError || txError;

  const announced = useRef(false);
  if (txSuccess && !announced.current) {
    announced.current = true;
    setIsRegistered(true);
    toast({ description: "Subname claimed successfully!", title: "Success" });
  }
  if (hasError && !announced.current) {
    announced.current = true;
    toast({ description: "Please check your wallet or try again.", title: "Transaction failed", variant: "destructive" });
  }

  return (
    <div className="mx-auto w-full max-w-2xl">
      <Card>
        <CardHeader>
          <CardTitle className="flex flex-col items-start gap-2 sm:flex-row sm:items-center sm:justify-between">
            <span>Claim your Lil Nouns subname</span>
          </CardTitle>
          <CardDescription>
            {isConnected ? (
              <>
                Connected as <span className="font-mono">{shortenAddress(address ?? "")}</span> on {chain?.name ?? "Unknown network"}.
              </>
            ) : (
              "Connect your wallet to start."
            )}
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div aria-live="polite" className="mb-4 text-sm text-muted-foreground" role="status">
            {isConnected && nounsLoading && "Fetching your Lil Nouns…"}
            {isConnected && !nounsLoading && !nounsError && `Owned Lil Nouns: ${ownedCount}`}
            {nounsError && "Could not fetch Lil Nouns. Using fallback if available."}
          </div>

          <div aria-busy={pending} aria-live="polite" className="space-y-3">
            <label className="text-sm font-medium" htmlFor="subdomain">
              Desired subname
            </label>
            <input
              aria-invalid={!!subdomainError}
              autoComplete="off"
              className="border-input bg-background text-foreground placeholder:text-muted-foreground focus-visible:ring-ring flex h-9 w-full rounded-md border px-3 py-1 text-sm shadow-xs transition-colors focus-visible:outline-none focus-visible:ring-1 disabled:cursor-not-allowed disabled:opacity-50"
              id="subdomain"
              inputMode="text"
              onBlur={() => { setSubdomainError(validateSubdomain(subdomain)); }}
              onChange={(e) => { setSubdomain(e.target.value); }}
              placeholder="e.g. lilnouns"
              type="text"
              value={subdomain}
            />
            {subdomainError ? <p className="text-destructive text-sm">{subdomainError}</p> : null}

            <div className="space-y-2 pt-2">
              <Button
                aria-disabled={!!subdomainDisabledReason || pending || isRegistered}
                aria-label="Claim subname"
                disabled={!!subdomainDisabledReason || pending || isRegistered}
                onClick={onSubmit}
                type="button"
              >
                {pending ? "Claiming…" : "Claim subname"}
              </Button>
              {subdomainDisabledReason && (
                <p className="text-sm text-muted-foreground" role="note">
                  {subdomainDisabledReason}
                </p>
              )}
              {isRegistered && (
                <p className="text-sm text-green-600" role="status">
                  Registration complete.
                </p>
              )}
            </div>
          </div>

          {mustChooseToken && nouns && (
            <>
              <Separator className="my-6" />
              <div className="flex flex-col items-start justify-between gap-2 sm:flex-row sm:items-center">
                <p className="text-sm text-muted-foreground">You have multiple Lil Nouns. Choose which to use.</p>
                <Button onClick={() => { setDialogOpen(true); }} variant="secondary">
                  Open selector
                </Button>
              </div>
              <NftGalleryDialog
                nfts={nouns}
                onOpenChange={setDialogOpen}
                onSelect={onTokenSelect}
                open={dialogOpen}
                pendingTokenId={selectedTokenId}
              />
            </>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
