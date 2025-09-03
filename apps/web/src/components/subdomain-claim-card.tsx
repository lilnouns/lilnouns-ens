import { Button } from "@repo/ui/components/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@repo/ui/components/card";
import { Input } from "@repo/ui/components/input";
import { Label } from "@repo/ui/components/label";
import { Separator } from "@repo/ui/components/separator";
import { Skeleton } from "@repo/ui/components/skeleton";
import { useCallback, useState } from "react";
import { toast } from "sonner";
import { useAccount } from "wagmi";

import { NftGalleryDialog } from "@/components/nft-gallery-dialog";
import { useSubdomainClaim } from "@/hooks/use-subdomain-claim";
import { shortenAddress } from "@/utils/address";
import { chain as configuredChain, chainId } from "@/config/chain";
import {
  lilNounsEnsMapperAddress,
  useReadLilNounsEnsMapperName,
  useReadLilNounsEnsMapperRootNode,
  useSimulateLilNounsEnsMapperClaimSubname,
} from "@/hooks/contracts";

export function SubdomainClaimCard() {
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
    txHash,
    validateSubdomain,
  } = useSubdomainClaim((options) => {
    const { description, title, variant } = options;
    if (variant === "destructive") {
      toast.error(title, { description });
    } else {
      toast(title, { description });
    }
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
    setSubdomainError,
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

  const isLoadingState = mustChooseToken && nounsLoading;

  const explorerBase = configuredChain.blockExplorers?.default.url;
  const mapperAddress = lilNounsEnsMapperAddress[configuredChain.id as 11155111];
  const contractHref = explorerBase && mapperAddress ? `${explorerBase}/address/${mapperAddress}` : undefined;
  // Dynamically resolve the root domain (e.g., "lilnouns.eth")
  const { data: rootNode } = useReadLilNounsEnsMapperRootNode({ chainId });
  const { data: resolvedRootName } = useReadLilNounsEnsMapperName({
    args: rootNode ? [rootNode as unknown as `0x${string}`] : undefined,
    chainId,
    query: { enabled: !!rootNode },
  });
  const fallbackRoot = "lilnouns.eth";
  const rootName = (resolvedRootName as string | undefined)?.trim() || fallbackRoot;
  const previewName = subdomain ? `${subdomain}.${rootName}` : undefined;

  // Pre-check availability via simulate when we know a tokenId
  const effectiveTokenId =
    ownedCount === 1 && firstTokenId != undefined
      ? firstTokenId
      : ownedCount > 1 && selectedTokenId
        ? BigInt(selectedTokenId)
        : undefined;
  const subdomainValidationError = validateSubdomain(subdomain);
  const shouldSimulate =
    !!effectiveTokenId &&
    !!subdomain &&
    !subdomainValidationError &&
    isConnected &&
    (chain?.id === configuredChain.id);
  const { data: simOk, error: simError, isLoading: simLoading } = useSimulateLilNounsEnsMapperClaimSubname({
    args: shouldSimulate ? [subdomain, effectiveTokenId!] : undefined,
    chainId,
    query: {
      enabled: shouldSimulate,
      staleTime: 15_000,
    },
  });

  let availabilityNote: string | undefined;
  if (simLoading) availabilityNote = "Checking availability…";
  else if (simError) {
    const msg = String((simError as Error)?.message || simError);
    if (msg.includes("AlreadyClaimed")) availabilityNote = "That subname is already claimed. Try another.";
    else if (msg.includes("InvalidLabel")) availabilityNote = "Invalid subname. Use a–z, 0–9, hyphen; 3–63 chars.";
    else if (msg.includes("PreexistingENSRecord")) availabilityNote = "This label collides with an existing ENS record.";
    else if (msg.includes("NotTokenOwner") || msg.includes("NotAuthorised")) availabilityNote = "You must claim with the owner of the selected Lil Noun.";
    else if (msg.includes("UnregisteredNode")) availabilityNote = "The root ENS node is not registered yet.";
    else availabilityNote = "Cannot claim this subname. Please try another or retry.";
  } else if (simOk) availabilityNote = "Available";

  const availabilityBlocksCta = !!simError && shouldSimulate;

  return (
    <div className="mx-auto w-full max-w-2xl">
      <Card>
        <CardHeader>
          <CardTitle className="flex flex-col items-start gap-2 sm:flex-row sm:items-center sm:justify-between">
            <span>Claim your lilnouns.eth subname</span>
          </CardTitle>
          <CardDescription>
            {isConnected ? (
              <>
                Connected as{" "}
                <span className="font-mono">
                  {shortenAddress(address ?? "")}
                </span>{" "}
                on {chain?.name ?? "Unknown network"}.
                {contractHref && (
                  <>
                    {" "}•{" "}
                    <a
                      className="underline underline-offset-2"
                      href={contractHref}
                      rel="noreferrer noopener"
                      target="_blank"
                    >
                      Contract
                    </a>
                  </>
                )}
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
            {isConnected && `Owned Lil Nouns: ${ownedCount.toString()}`}
            {mustChooseToken && nounsLoading && (
              <div className="mt-2">
                <Skeleton className="h-3 w-40" />
              </div>
            )}
            {mustChooseToken && nounsError && "Error loading Lil Nouns list."}
          </div>

          <div aria-busy={pending} aria-live="polite" className="space-y-3">
            <Label className="text-sm" htmlFor="subdomain">
              Choose a subname
            </Label>
            <div>
              <div className="relative">
                <Input
                  aria-invalid={!!subdomainError}
                  aria-label="Subname label"
                  autoComplete="off"
                  id="subdomain"
                  inputMode="text"
                  onBlur={() => {
                    setSubdomainError(validateSubdomain(subdomain));
                  }}
                  onChange={(event) => {
                    setSubdomain(event.target.value);
                  }}
                  placeholder="yourname"
                  type="text"
                  value={subdomain}
                />
                <span
                  aria-hidden="true"
                  className="pointer-events-none absolute inset-y-0 right-3 flex items-center text-sm text-muted-foreground"
                >
                  .{rootName}
                </span>
              </div>
              <p className="text-muted-foreground mt-1 text-xs">
                Allowed: a–z, 0–9, hyphen • 3–63 chars • case-insensitive
              </p>
              {previewName && (
                <p className="mt-1 text-sm">Preview: <span className="font-mono">{previewName}</span></p>
              )}
            </div>
            {subdomainError ? (
              <p className="text-destructive text-sm">{subdomainError}</p>
            ) : undefined}

            <div className="space-y-2 pt-2">
              <Button
                aria-disabled={
                  !!subdomainDisabledReason ||
                  isLoadingState ||
                  pending ||
                  isRegistered ||
                  availabilityBlocksCta
                }
                aria-label={previewName ? `Claim ${previewName}` : "Claim subname"}
                disabled={
                  !!subdomainDisabledReason ||
                  isLoadingState ||
                  pending ||
                  isRegistered ||
                  availabilityBlocksCta
                }
                onClick={onSubmit}
                type="button"
              >
                {pending ? "Claiming…" : previewName ? `Claim ${previewName}` : "Claim subname"}
              </Button>
              {availabilityNote && (
                <p className={`text-sm ${availabilityBlocksCta ? "text-destructive" : "text-green-600"}`}>
                  {availabilityNote}
                </p>
              )}
              {subdomainDisabledReason && (
                <p className="text-muted-foreground text-sm" role="note">
                  {subdomainDisabledReason}
                </p>
              )}
              {isRegistered && (
                <SuccessActions
                  explorerBase={explorerBase}
                  name={previewName ?? ""}
                  txHash={txHash}
                />
              )}
              <p className="text-muted-foreground mt-3 text-xs">
                Network: {chain?.name ?? "Unknown"} • Cost: gas only
                {contractHref && (
                  <>
                    {" "}•{" "}
                    <a
                      className="underline underline-offset-2"
                      href={contractHref}
                      rel="noreferrer noopener"
                      target="_blank"
                    >
                      View contract
                    </a>
                  </>
                )}
              </p>
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
                <p className="text-destructive text-sm">
                  Error loading your Lil Nouns. Please try again.
                </p>
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

function SuccessActions({ name, explorerBase, txHash }: { name: string; explorerBase?: string; txHash?: `0x${string}` }) {
  const [copied, setCopied] = useState(false);
  const ensHref = name ? `https://app.ens.domains/name/${encodeURIComponent(name)}` : undefined;
  const txHref = explorerBase && txHash ? `${explorerBase}/tx/${txHash}` : undefined;

  return (
    <div className="flex flex-wrap items-center gap-2" role="status">
      <p className="text-sm text-green-600">Success! You claimed <span className="font-mono">{name}</span></p>
      {ensHref && (
        <Button asChild size="sm" variant="secondary">
          <a href={ensHref} target="_blank" rel="noreferrer noopener">View on ENS</a>
        </Button>
      )}
      {txHref && (
        <Button asChild size="sm" variant="ghost">
          <a href={txHref} target="_blank" rel="noreferrer noopener">View transaction</a>
        </Button>
      )}
      <Button
        onClick={async () => {
          try {
            await navigator.clipboard.writeText(name);
            setCopied(true);
            setTimeout(() => setCopied(false), 1500);
          } catch {}
        }}
        size="sm"
        variant="ghost"
      >
        {copied ? "Copied" : "Copy name"}
      </Button>
    </div>
  );
}
