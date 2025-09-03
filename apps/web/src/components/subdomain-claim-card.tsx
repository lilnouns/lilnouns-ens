import { Button } from "@repo/ui/components/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@repo/ui/components/card";
import { Separator } from "@repo/ui/components/separator";
import { Skeleton } from "@repo/ui/components/skeleton";
import { useCallback, useState } from "react";
import { useAccount } from "wagmi";

import { NftGalleryDialog } from "@/components/nft-gallery-dialog";
import { useToast } from "@/components/toast";
import { useSubdomainClaim } from "@/hooks/use-subdomain-claim";
import { shortenAddress } from "@/utils/address";

export function SubdomainClaimCard() {
  const { toast } = useToast();
  const { address, chain, isConnected } = useAccount();

  const [dialogOpen, setDialogOpen] = useState(false);
  const [selectedTokenId, setSelectedTokenId] = useState<string | undefined>();

  const {
    claim,
    firstTokenId,
    firstTokenLoading,
    isRegistered,
    mustChooseToken,
    nouns,
    nounsError,
    nounsLoading,
    ownedCount,
    pending,
    setSubdomain,
    setSubdomainError,
    subdomain,
    subdomainDisabledReason,
    subdomainError,
    validateSubdomain,
  } = useSubdomainClaim((options) => {
    toast({ description: options.description, title: options.title, variant: options.variant });
  });

  const onSubmit = useCallback(() => {
    const error = validateSubdomain(subdomain);
    setSubdomainError(error);
    if (error) return;
    if (!isConnected) return;
    if (ownedCount === 0) return;
    if (ownedCount === 1) {
      if (firstTokenId != undefined) {
        claim(firstTokenId);
      } else if (firstTokenLoading) {
        toast({ description: "Fetching your token ID. Please try again in a moment.", title: "Please wait" });
      } else {
        toast({ description: "Could not resolve your token ID. Please try again.", title: "Token not found", variant: "destructive" });
      }
      return;
    }
    if (ownedCount > 1) {
      setDialogOpen(true);
      return;
    }
    toast({ description: "Unknown state; please try again.", title: "Unable to proceed" });
  }, [validateSubdomain, subdomain, setSubdomainError, isConnected, ownedCount, firstTokenId, firstTokenLoading, claim, toast]);

  const onTokenSelect = useCallback(
    (tokenId: string) => {
      setSelectedTokenId(tokenId);
      setDialogOpen(false);
      claim(BigInt(tokenId));
    },
    [claim],
  );

  const isLoadingState = mustChooseToken && nounsLoading;

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
                Connected as{" "}
                <span className="font-mono">
                  {shortenAddress(address ?? "")}
                </span>{" "}
                on {chain?.name ?? "Unknown network"}.
              </>
            ) : (
              "Connect your wallet to start."
            )}
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div aria-live="polite" className="text-muted-foreground mb-4 text-sm" role="status">
            {isConnected && `Owned Lil Nouns: ${ownedCount.toString()}`}
            {mustChooseToken && nounsLoading && (
              <div className="mt-2">
                <Skeleton className="h-3 w-40" />
              </div>
            )}
            {mustChooseToken && nounsError && "Error loading Lil Nouns list."}
          </div>

          <div aria-busy={pending} aria-live="polite" className="space-y-3">
            <label className="text-sm font-medium" htmlFor="subdomain">
              Desired subname
            </label>
            <input
              aria-invalid={!!subdomainError}
              autoComplete="off"
              className="border-input bg-background text-foreground placeholder:text-muted-foreground focus-visible:ring-ring shadow-xs flex h-9 w-full rounded-md border px-3 py-1 text-sm transition-colors focus-visible:outline-none focus-visible:ring-1 disabled:cursor-not-allowed disabled:opacity-50"
              id="subdomain"
              inputMode="text"
              onBlur={() => {
                setSubdomainError(validateSubdomain(subdomain));
              }}
              onChange={(event) => {
                setSubdomain(event.target.value);
              }}
              placeholder="e.g. lilnouns"
              type="text"
              value={subdomain}
            />
            {subdomainError ? (
              <p className="text-destructive text-sm">{subdomainError}</p>
            ) : undefined}

            <div className="space-y-2 pt-2">
              <Button
                aria-disabled={
                  !!subdomainDisabledReason || isLoadingState || pending || isRegistered
                }
                aria-label="Claim subname"
                disabled={
                  !!subdomainDisabledReason || isLoadingState || pending || isRegistered
                }
                onClick={onSubmit}
                type="button"
              >
                {pending ? "Claiming…" : "Claim subname"}
              </Button>
              {subdomainDisabledReason && (
                <p className="text-muted-foreground text-sm" role="note">
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

          {mustChooseToken && (
            <>
              <Separator className="my-6" />
              {nounsLoading && (
                <div className="grid grid-cols-2 gap-3 p-1 sm:grid-cols-3">
                  {Array.from({ length: 6 }).map((_, index) => (
                    <div className="w-full" key={index}>
                      <Skeleton className="aspect-square w-full rounded-md" />
                      <div className="mt-2 space-y-2">
                        <Skeleton className="h-3 w-3/4" />
                        <Skeleton className="h-3 w-1/2" />
                      </div>
                    </div>
                  ))}
                </div>
              )}
              {nounsError && (
                <p className="text-destructive text-sm">Error loading your Lil Nouns. Please try again.</p>
              )}
              {nouns && !nounsLoading && !nounsError && (
                <>
                  <div className="flex flex-col items-start justify-between gap-2 sm:flex-row sm:items-center">
                    <p className="text-muted-foreground text-sm">
                      You have multiple Lil Nouns. Choose which to use.
                    </p>
                    <Button
                      onClick={() => {
                        setDialogOpen(true);
                      }}
                      variant="secondary"
                    >
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
            </>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
