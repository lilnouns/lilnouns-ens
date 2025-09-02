import {
  useReadLilNounsTokenBalanceOf,
  useReadLilNounsTokenTokenOfOwnerByIndex,
} from "@nekofar/lilnouns/contracts";
import { Button } from "@repo/ui/components/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@repo/ui/components/card";
import { Separator } from "@repo/ui/components/separator";
import { Skeleton } from "@repo/ui/components/skeleton";
import { useQuery } from "@tanstack/react-query";
import { useCallback, useMemo, useRef, useState } from "react";
import { useAccount, useWaitForTransactionReceipt } from "wagmi";

import type { OwnedNft } from "@/lib/types";

import { NftGalleryDialog } from "@/components/nft-gallery-dialog";
import { useToast } from "@/components/toast";
import { chainId, chain as configuredChain } from "@/config/chain";
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

  // On-chain balance via Lil Nouns token
  const {
    data: balance,
    isError: balanceError,
    isLoading: balanceLoading,
  } = useReadLilNounsTokenBalanceOf({
    args: address ? [address] : undefined,
    chainId,
    query: { enabled: isConnected && !!address },
  });

  const ownedCount = Number(balance ?? 0n);

  // Prefetch the first token id for single-token direct claim
  const { data: firstTokenId, isLoading: firstTokenLoading } =
    useReadLilNounsTokenTokenOfOwnerByIndex({
      args: address ? [address, 0n] : undefined,
      chainId,
      query: { enabled: isConnected && !!address && ownedCount === 1 },
    });

  // Only use subgraph when the user has multiple tokens to populate the gallery
  const {
    data: nouns,
    isError: nounsError,
    isLoading: nounsLoading,
  } = useQuery<OwnedNft[]>({
    enabled: isConnected && !!address && ownedCount > 1,
    queryFn: () => fetchOwnedLilNouns(address),
    queryKey: ["ownedLilNouns", address],
  });

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

  // const canClaimDirectly = isConnected && ownedCount === 1;
  const mustChooseToken = isConnected && ownedCount > 1;
  const cannotClaim = isConnected && ownedCount === 0;

  const validateSubdomain = useCallback((value: string): string | undefined => {
    if (value.length < 3) return "Must be at least 3 characters";
    if (value.length > 63) return "Must be at most 63 characters";
    if (!/^[a-z0-9-]+$/.test(value))
      return "Only lowercase letters, digits, and hyphens";
    if (!/^[a-z0-9]/.test(value)) return "Must start with a letter or digit";
    if (!/[a-z0-9]$/.test(value)) return "Must end with a letter or digit";
    return undefined;
  }, []);

  const [subdomainError, setSubdomainError] = useState<string | undefined>();

  const claim = useCallback(
    (tokenId: bigint) => {
      if (!address) return;
      try {
        // Wagmi config is restricted to the configured chain; write will use it.
        writeContract({ args: [subdomain, tokenId] });
      } catch {
        toast({
          description: "Could not submit transaction.",
          title: "Transaction error",
          variant: "destructive",
        });
      }
    },
    [address, subdomain, toast, writeContract],
  );

  const onSubmit = useCallback(() => {
    const error = validateSubdomain(subdomain);
    setSubdomainError(error);
    if (error) {
      toast({
        description: error,
        title: "Invalid subname",
        variant: "destructive",
      });
      return;
    }
    if (!isConnected) {
      toast({
        description: "Please connect your wallet first.",
        title: "Connect wallet",
      });
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
    if (ownedCount === 1) {
      if (firstTokenId != undefined) {
        claim(firstTokenId satisfies bigint);
      } else if (firstTokenLoading) {
        toast({
          description: "Fetching your token ID. Please try again in a moment.",
          title: "Please wait",
        });
      } else {
        toast({
          description: "Could not resolve your token ID. Please try again.",
          title: "Token not found",
          variant: "destructive",
        });
      }
      return;
    }
    if (ownedCount > 1) {
      setDialogOpen(true);
      return;
    }
    toast({
      description: "Unknown state; please try again.",
      title: "Unable to proceed",
    });
  }, [
    validateSubdomain,
    subdomain,
    isConnected,
    ownedCount,
    firstTokenId,
    firstTokenLoading,
    claim,
    toast,
  ]);

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
    if (chain?.id !== chainId)
      return `Wrong network. Please switch to ${configuredChain.name}.`;
    if (balanceError) return "Error loading Lil Nouns";
    if (mustChooseToken && nounsError) return "Error loading Lil Nouns";
    if (cannotClaim) return "You do not have a Lil Noun";
    return undefined;
  }, [
    isConnected,
    chain?.id,
    balanceError,
    mustChooseToken,
    nounsError,
    cannotClaim,
  ]);

  const pending = isWriting || txPending;
  const isLoadingState = balanceLoading || (mustChooseToken && nounsLoading);
  const hasError = !!writeError || txError;

  const announced = useRef(false);
  if (txSuccess && !announced.current) {
    announced.current = true;
    setIsRegistered(true);
    toast({ description: "Subname claimed successfully!", title: "Success" });
  }
  if (hasError && !announced.current) {
    announced.current = true;
    toast({
      description: "Please check your wallet or try again.",
      title: "Transaction failed",
      variant: "destructive",
    });
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
          <div
            aria-live="polite"
            className="text-muted-foreground mb-4 text-sm"
            role="status"
          >
            {isConnected && balanceLoading ? (
              <Skeleton className="h-4 w-48" />
            ) : (
              <>
                {isConnected &&
                  !balanceError &&
                  `Owned Lil Nouns: ${ownedCount.toString()}`}
                {balanceError &&
                  "Could not fetch wallet balance. Using fallback if available."}
              </>
            )}
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
