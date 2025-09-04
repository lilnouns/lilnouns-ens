import { useReadLilNounsTokenBalanceOf } from "@nekofar/lilnouns/contracts";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@repo/ui/components/card";
import { useCallback, useMemo, useState } from "react";
import { isBigInt } from "remeda";
import { toast } from "sonner";
import { useAccount } from "wagmi";

import { MultiTokenSection } from "@/components/subname-claim/multi-token-section";
import { ClaimSection } from "@/components/subname-claim/claim-section";
import { HeaderDescription } from "@/components/subname-claim/header-description";
import { NameInputWithSuffix } from "@/components/subname-claim/name-input-with-suffix";
import { OwnershipStatus } from "@/components/subname-claim/ownership-status";
import { chainId, chain as configuredChain } from "@/config/chain";
import { useClaimAvailability } from "@/hooks/use-claim-availability";
import { useRootName } from "@/hooks/use-root-name";
import { useSubnameClaim } from "@/hooks/use-subname-claim";
import { getLilNounsEnsMapperContractHref } from "@/utils/links";
import { computeEffectiveTokenId } from "@/utils/subname-claim";

export function SubnameClaimCard() {
  const { address, chain, isConnected } = useAccount();

  const [dialogOpen, setDialogOpen] = useState(false);
  const [selectedTokenId, setSelectedTokenId] = useState<string | undefined>();

  const { data: ownedCount } = useReadLilNounsTokenBalanceOf({
    args: address ? [address] : undefined,
    chainId,
    query: { enabled: isConnected && !!address },
  });

  const {
    claim,
    firstTokenId,
    firstTokenLoading,
    isRegistered,
    mustChooseToken,
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
    if (ownedCount == 0n) return;
    if (ownedCount == 1n) {
      handleSingleTokenClaim();
      return;
    }
    if (isBigInt(ownedCount) && ownedCount > 1) {
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

  const isLoadingState = mustChooseToken;
  const explorerBase = configuredChain.blockExplorers?.default.url;
  const contractHref = getLilNounsEnsMapperContractHref();
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
              isConnected={isConnected}
            />
          </CardDescription>
        </CardHeader>
        <CardContent>
          <OwnershipStatus
            isConnected={isConnected}
            mustChooseToken={mustChooseToken}
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
            address={address}
            dialogOpen={dialogOpen}
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
