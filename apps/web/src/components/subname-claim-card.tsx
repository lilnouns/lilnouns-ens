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
import { useCallback, useMemo, useState } from "react";
import { toast } from "sonner";
import { useAccount } from "wagmi";

import type { OwnedNft } from "@/lib/types";

import { NftGalleryDialog } from "@/components/nft-gallery-dialog";
import { chainId, chain as configuredChain } from "@/config/chain";
import {
  lilNounsEnsMapperAddress,
  useReadLilNounsEnsMapperName,
  useReadLilNounsEnsMapperRootLabel,
  useReadLilNounsEnsMapperRootNode,
} from "@/hooks/contracts";
import { useClaimAvailability } from "@/hooks/use-claim-availability";
import { useSubnameClaim } from "@/hooks/use-subname-claim";
import { shortenAddress } from "@/utils/address";

export function SubnameClaimCard() {
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
    setSubname,
    setSubnameError,
    subname,
    subnameDisabledReason,
    subnameError,
    txHash,
    validateSubname,
  } = useSubnameClaim((options) => {
    const { description, title, variant } = options;
    if (variant === "destructive") {
      toast.error(title, { description });
    } else {
      toast(title, { description });
    }
  });

  const handleSingleTokenClaim = useCallback(() => {
    if (firstTokenId != undefined) {
      claim(firstTokenId);
      return;
    }
    if (firstTokenLoading) {
      toast("Please wait", {
        description: "Fetching your token ID. Please try again in a moment.",
      });
      return;
    }
    toast.error("Token not found", {
      description: "Could not resolve your token ID. Please try again.",
    });
  }, [claim, firstTokenId, firstTokenLoading]);

  const onSubmit = useCallback(() => {
    const error = validateSubname(subname);
    setSubnameError(error);
    if (error || !isConnected) return;
    if (ownedCount === 0) return;
    if (ownedCount === 1) {
      handleSingleTokenClaim();
      return;
    }
    if (ownedCount > 1) {
      setDialogOpen(true);
      return;
    }
    toast("Unable to proceed", {
      description: "Unknown state; please try again.",
    });
  }, [
    validateSubname,
    subname,
    setSubnameError,
    isConnected,
    ownedCount,
    handleSingleTokenClaim,
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
  const contractHref = getContractHref();
  const rootName = useRootName();
  const previewName = useMemo(
    () => (subname ? `${subname}.${rootName}` : undefined),
    [subname, rootName],
  );

  const effectiveTokenId = useMemo(
    () => computeEffectiveTokenId(ownedCount, firstTokenId, selectedTokenId),
    [ownedCount, firstTokenId, selectedTokenId],
  );
  const subnameValidationError = validateSubname(subname);
  const shouldSimulate =
    !!effectiveTokenId &&
    !!subname &&
    !subnameValidationError &&
    isConnected &&
    chain?.id === configuredChain.id;
  const { blocksCta: availabilityBlocksCta, note: availabilityNote } =
    useClaimAvailability(shouldSimulate, subname, effectiveTokenId);

  return (
    <div className="mx-auto w-full max-w-2xl">
      <Card>
        <CardHeader>
          <CardTitle className="flex flex-col items-start gap-2 sm:flex-row sm:items-center sm:justify-between">
            <span>Claim your lilnouns.eth subname</span>
          </CardTitle>
          <CardDescription>
            <HeaderDescription
              address={address}
              chainName={chain?.name}
              contractHref={contractHref}
              isConnected={isConnected}
            />
          </CardDescription>
        </CardHeader>
        <CardContent>
          <OwnershipStatus
            isConnected={isConnected}
            mustChooseToken={mustChooseToken}
            nounsError={nounsError}
            nounsLoading={nounsLoading}
            ownedCount={ownedCount}
          />

          <div aria-busy={pending} aria-live="polite" className="space-y-3">
            <NameInputWithSuffix
              onBlurValidate={() => {
                setSubnameError(validateSubname(subname));
              }}
              onChange={(v) => {
                setSubname(v);
              }}
              previewName={previewName}
              rootName={rootName}
              subname={subname}
              subnameError={subnameError}
            />

            <div className="space-y-2 pt-2">
              <ClaimSection
                availabilityBlocksCta={availabilityBlocksCta}
                availabilityNote={availabilityNote}
                chainName={chain?.name}
                contractHref={contractHref}
                explorerBase={explorerBase}
                isRegistered={isRegistered}
                isSubmitting={pending}
                isUnavailable={!!subnameDisabledReason || isLoadingState}
                onSubmit={onSubmit}
                previewName={previewName}
                subnameDisabledReason={subnameDisabledReason}
                txHash={txHash}
              />
            </div>
          </div>

          <MultiTokenSection
            dialogOpen={dialogOpen}
            nouns={nouns}
            nounsError={nounsError}
            nounsLoading={nounsLoading}
            onOpenChange={setDialogOpen}
            onOpenDialog={() => {
              setDialogOpen(true);
            }}
            onTokenSelect={onTokenSelect}
            pendingTokenId={selectedTokenId}
            shouldShow={mustChooseToken}
          />
        </CardContent>
      </Card>
    </div>
  );
}

function ClaimSection({
  availabilityBlocksCta,
  availabilityNote,
  chainName,
  contractHref,
  explorerBase,
  isRegistered,
  isSubmitting,
  isUnavailable,
  onSubmit,
  previewName,
  subnameDisabledReason,
  txHash,
}: Readonly<{
  availabilityBlocksCta: boolean;
  availabilityNote?: string;
  chainName?: string;
  contractHref?: string;
  explorerBase?: string;
  isRegistered: boolean;
  isSubmitting: boolean;
  isUnavailable: boolean;
  onSubmit: () => void;
  previewName?: string;
  subnameDisabledReason?: string;
  txHash?: `0x${string}`;
}>) {
  const disabled =
    isUnavailable || isSubmitting || isRegistered || availabilityBlocksCta;
  const label = previewName ? `Claim ${previewName}` : "Claim subname";
  return (
    <>
      <Button
        aria-disabled={disabled}
        aria-label={label}
        disabled={disabled}
        onClick={onSubmit}
        type="button"
      >
        {isSubmitting ? "Claiming…" : label}
      </Button>
      {availabilityNote && (
        <p
          className={`text-sm ${availabilityBlocksCta ? "text-destructive" : "text-green-600"}`}
        >
          {availabilityNote}
        </p>
      )}
      {subnameDisabledReason && (
        <p className="text-muted-foreground text-sm" role="note">
          {subnameDisabledReason}
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
        Network: {chainName ?? "Unknown"} • Cost: gas only
        {contractHref && (
          <>
            {" "}
            •{" "}
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
    </>
  );
}

/** Choose which tokenId to use for claim simulation/submission. */
function computeEffectiveTokenId(
  ownedCount: number,
  firstTokenId: bigint | undefined,
  selectedTokenId: string | undefined,
): bigint | undefined {
  if (ownedCount === 1 && firstTokenId != undefined) return firstTokenId;
  if (ownedCount > 1 && selectedTokenId) return BigInt(selectedTokenId);
  return undefined;
}

// availability hook moved to hooks/use-claim-availability.ts

/** Build block explorer contract link based on current chain. */
function getContractHref(): string | undefined {
  const explorer = configuredChain.blockExplorers?.default.url;
  const addr = lilNounsEnsMapperAddress[configuredChain.id as 11_155_111];
  return explorer && addr ? `${explorer}/address/${addr}` : undefined;
}

function HeaderDescription({
  address,
  chainName,
  contractHref,
  isConnected,
}: Readonly<{
  address?: string;
  chainName?: string;
  contractHref?: string;
  isConnected: boolean;
}>) {
  if (!isConnected) return <>Connect your wallet to start.</>;
  return (
    <>
      Connected as{" "}
      <span className="font-mono">{shortenAddress(address ?? "")}</span> on{" "}
      {chainName ?? "Unknown network"}.
      {contractHref && (
        <>
          {" "}
          •{" "}
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
  );
}

function MultiTokenSection({
  dialogOpen,
  nouns,
  nounsError,
  nounsLoading,
  onOpenChange,
  onOpenDialog,
  onTokenSelect,
  pendingTokenId,
  shouldShow,
}: Readonly<{
  dialogOpen: boolean;
  nouns?: OwnedNft[];
  nounsError: boolean;
  nounsLoading: boolean;
  onOpenChange: (open: boolean) => void;
  onOpenDialog: () => void;
  onTokenSelect: (tokenId: string) => void;
  pendingTokenId?: string;
  shouldShow: boolean;
}>) {
  if (!shouldShow) return;
  return (
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
            <Button onClick={onOpenDialog} variant="secondary">
              Open selector
            </Button>
          </div>
          <NftGalleryDialog
            nfts={nouns}
            onOpenChange={onOpenChange}
            onSelect={onTokenSelect}
            open={dialogOpen}
            pendingTokenId={pendingTokenId}
          />
        </>
      )}
    </>
  );
}

function NameInputWithSuffix({
  onBlurValidate,
  onChange,
  previewName,
  rootName,
  subname,
  subnameError,
}: Readonly<{
  onBlurValidate: () => void;
  onChange: (v: string) => void;
  previewName?: string;
  rootName: string;
  subname: string;
  subnameError?: string;
}>) {
  return (
    <>
      <Label className="text-sm" htmlFor="subname">
        Choose a subname
      </Label>
      <div>
        <div className="relative">
          <Input
            aria-invalid={!!subnameError}
            aria-label="Subname label"
            autoComplete="off"
            id="subname"
            inputMode="text"
            onBlur={onBlurValidate}
            onChange={(event) => {
              onChange(event.target.value);
            }}
            placeholder="yourname"
            type="text"
            value={subname}
          />
          <span
            aria-hidden="true"
            className="text-muted-foreground pointer-events-none absolute inset-y-0 right-3 flex items-center text-sm"
          >
            .{rootName}
          </span>
        </div>
        <p className="text-muted-foreground mt-1 text-xs">
          Allowed: a–z, 0–9, hyphen • 3–63 chars • case-insensitive
        </p>
        {previewName && (
          <p className="mt-1 text-sm">
            Preview: <span className="font-mono">{previewName}</span>
          </p>
        )}
      </div>
      {subnameError ? (
        <p className="text-destructive text-sm">{subnameError}</p>
      ) : undefined}
    </>
  );
}

function OwnershipStatus({
  isConnected,
  mustChooseToken,
  nounsError,
  nounsLoading,
  ownedCount,
}: Readonly<{
  isConnected: boolean;
  mustChooseToken: boolean;
  nounsError: boolean;
  nounsLoading: boolean;
  ownedCount: number;
}>) {
  return (
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
  );
}

function SuccessActions({
  explorerBase,
  name,
  txHash,
}: Readonly<{ explorerBase?: string; name: string; txHash?: `0x${string}` }>) {
  const [copied, setCopied] = useState(false);
  const ensHref = name
    ? `https://app.ens.domains/name/${encodeURIComponent(name)}`
    : undefined;
  const txHref =
    explorerBase && txHash ? `${explorerBase}/tx/${txHash}` : undefined;

  return (
    <div className="flex flex-wrap items-center gap-2" role="status">
      <p className="text-sm text-green-600">
        Success! You claimed <span className="font-mono">{name}</span>
      </p>
      {ensHref && (
        <Button asChild size="sm" variant="secondary">
          <a href={ensHref} rel="noreferrer noopener" target="_blank">
            View on ENS
          </a>
        </Button>
      )}
      {txHref && (
        <Button asChild size="sm" variant="ghost">
          <a href={txHref} rel="noreferrer noopener" target="_blank">
            View transaction
          </a>
        </Button>
      )}
      <Button
        onClick={async () => {
          try {
            await navigator.clipboard.writeText(name);
            setCopied(true);
            setTimeout(() => {
              setCopied(false);
            }, 1500);
          } catch {
            /* empty */
          }
        }}
        size="sm"
        variant="ghost"
      >
        {copied ? "Copied" : "Copy name"}
      </Button>
    </div>
  );
}

/** Resolve ENS root domain name via contract; fallback to lilnouns.eth. */
function useRootName(): string {
  const { data: rootNode } = useReadLilNounsEnsMapperRootNode({ chainId });
  const enabled = !!rootNode;
  const { data: resolved } = useReadLilNounsEnsMapperName({
    args: enabled ? [rootNode as unknown as `0x${string}`] : undefined,
    chainId,
    query: { enabled },
  });
  const { data: rootLabel } = useReadLilNounsEnsMapperRootLabel({
    chainId,
    query: { enabled },
  });
  const trimmed = (resolved ?? "").trim();
  if (trimmed.length > 0) return trimmed;
  const label = (rootLabel ?? "").trim();
  if (label.length > 0) return `${label}.eth`;
  return "lilnouns.eth";
}
