import { useCallback, useMemo, useRef, useState } from "react";
import { useAccount, useWaitForTransactionReceipt, useWriteContract } from "wagmi";
import { useQuery } from "@tanstack/react-query";

import { Button } from "@repo/ui/components/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@repo/ui/components/card";
import { Separator } from "@repo/ui/components/separator";

import { WalletConnectButton } from "@/components/wallet-connect-button";
import { NftGalleryDialog } from "@/components/nft-gallery-dialog";
import { useToast } from "@/components/toast";
import { fetchOwnedLilNouns } from "@/lib/subgraph-client";
import { registrarAbi } from "@/lib/abis/registrar";
import type { OwnedNft } from "@/lib/types";
import { shortenAddress } from "@/utils/address";

const REGISTRAR_ADDRESS = (import.meta.env.VITE_REGISTRAR_ADDRESS as `0x${string}` | undefined) ??
  "0x0000000000000000000000000000000000000000";

export function SubdomainClaimCard() {
  const { toast } = useToast();
  const { address, isConnected, chain } = useAccount();
  const [isRegistered, setIsRegistered] = useState(false);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [selectedTokenId, setSelectedTokenId] = useState<string | undefined>(undefined);
  const [subdomain, setSubdomain] = useState("");

  const { data: nouns, isLoading: nounsLoading, isError: nounsError } = useQuery<OwnedNft[]>({
    enabled: isConnected && !!address,
    queryKey: ["ownedLilNouns", address],
    queryFn: () => fetchOwnedLilNouns(address as `0x${string}`),
  });

  const ownedCount = nouns?.length ?? 0;

  const { writeContract, data: txHash, error: writeError, isPending: isWriting } = useWriteContract();
  const { isLoading: txPending, isSuccess: txSuccess, isError: txError } = useWaitForTransactionReceipt({
    hash: txHash,
    query: { enabled: !!txHash },
  });

  const canClaimDirectly = isConnected && ownedCount === 1;
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

  const [subdomainError, setSubdomainError] = useState<string | undefined>(undefined);

  const claim = useCallback(
    (tokenId: bigint) => {
      if (!address) return;
      try {
        writeContract({
          abi: registrarAbi,
          address: REGISTRAR_ADDRESS,
          functionName: "claimSubname",
          args: [subdomain, tokenId],
        });
      } catch {
        toast({ title: "Transaction error", description: "Could not submit transaction.", variant: "destructive" });
      }
    },
    [address, subdomain, toast, writeContract],
  );

  const onSubmit = useCallback(() => {
    const err = validateSubdomain(subdomain);
    setSubdomainError(err);
    if (err) {
      toast({ title: "Invalid subdomain", description: err, variant: "destructive" });
      return;
    }
    if (!isConnected) {
      toast({ title: "Connect wallet", description: "Please connect your wallet first." });
      return;
    }
    if (ownedCount === 0) {
      toast({
        title: "No Lil Nouns found",
        description: "You must own at least one Lil Noun to claim.",
        variant: "destructive",
      });
      return;
    }
    if (ownedCount === 1 && nouns && nouns[0]) {
      claim(BigInt(nouns[0].tokenId));
      return;
    }
    if (ownedCount > 1) {
      setDialogOpen(true);
      return;
    }
    toast({ title: "Unable to proceed", description: "Unknown state; please try again." });
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
    return undefined;
  }, [isConnected, nounsLoading, nounsError, cannotClaim]);

  const pending = isWriting || txPending;
  const hasError = !!writeError || txError;

  const announced = useRef(false);
  if (txSuccess && !announced.current) {
    announced.current = true;
    setIsRegistered(true);
    toast({ title: "Success", description: "Subdomain claimed successfully!" });
  }
  if (hasError && !announced.current) {
    announced.current = true;
    toast({ title: "Transaction failed", description: "Please check your wallet or try again.", variant: "destructive" });
  }

  return (
    <div className="mx-auto w-full max-w-2xl">
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center justify-between">
            Claim your Lil Nouns subdomain
            <WalletConnectButton />
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
          <div className="mb-4 text-sm text-muted-foreground" role="status" aria-live="polite">
            {isConnected && nounsLoading && "Fetching your Lil Nouns…"}
            {isConnected && !nounsLoading && !nounsError && `Owned Lil Nouns: ${ownedCount}`}
            {nounsError && "Could not fetch Lil Nouns. Using fallback if available."}
          </div>

          <div className="space-y-3" aria-busy={pending} aria-live="polite">
            <label htmlFor="subdomain" className="text-sm font-medium">
              Desired subdomain
            </label>
            <input
              id="subdomain"
              type="text"
              value={subdomain}
              onChange={(e) => setSubdomain(e.target.value)}
              onBlur={() => setSubdomainError(validateSubdomain(subdomain))}
              placeholder="e.g. lilnouna"
              autoComplete="off"
              inputMode="text"
              aria-invalid={!!subdomainError}
              className="border-input bg-background text-foreground placeholder:text-muted-foreground focus-visible:ring-ring flex h-9 w-full rounded-md border px-3 py-1 text-sm shadow-xs transition-colors focus-visible:outline-none focus-visible:ring-1 disabled:cursor-not-allowed disabled:opacity-50"
            />
            {subdomainError ? <p className="text-destructive text-sm">{subdomainError}</p> : null}

            <div className="space-y-2 pt-2">
              <Button
                type="button"
                onClick={onSubmit}
                disabled={!!subdomainDisabledReason || pending || isRegistered}
                aria-disabled={!!subdomainDisabledReason || pending || isRegistered}
                aria-label="Claim subdomain"
              >
                {pending ? "Claiming…" : "Claim subdomain"}
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
              <div className="flex items-center justify-between">
                <p className="text-sm text-muted-foreground">You have multiple Lil Nouns. Choose which to use.</p>
                <Button variant="secondary" onClick={() => setDialogOpen(true)}>
                  Open selector
                </Button>
              </div>
              <NftGalleryDialog
                open={dialogOpen}
                onOpenChange={setDialogOpen}
                nfts={nouns}
                onSelect={onTokenSelect}
                pendingTokenId={selectedTokenId}
              />
            </>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

