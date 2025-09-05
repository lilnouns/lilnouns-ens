import { useReadLilNounsTokenBalanceOf } from "@nekofar/lilnouns/contracts";
import { Button } from "@repo/ui/components/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@repo/ui/components/card";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@repo/ui/components/dialog";
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { isBigInt, isNonNullish, isNullish } from "remeda";
import { toast } from "sonner";
import { useAccount } from "wagmi";

import { ClaimSection } from "@/components/subname-claim/claim-section";
import { HeaderDescription } from "@/components/subname-claim/header-description";
import { MultiTokenSection } from "@/components/subname-claim/multi-token-section";
import { NameInputWithSuffix } from "@/components/subname-claim/name-input-with-suffix";
import { OwnershipStatus } from "@/components/subname-claim/ownership-status";
import { chainId, chain as configuredChain } from "@/config/chain";
import { useClaimAvailability } from "@/hooks/use-claim-availability";
import { useRootName } from "@/hooks/use-root-name";
import { useSubnameClaim } from "@/hooks/use-subname-claim";
import { getLilNounsEnsMapperContractHref } from "@/utils/links";
import { computeEffectiveTokenId } from "@/utils/subname-claim";

export function SubnameClaimCard({ onClaimSuccess }: Readonly<{ onClaimSuccess?: () => void }>) {
  const { address, chain, isConnected } = useAccount();

  const [dialogOpen, setDialogOpen] = useState(false);
  const [selectedTokenId, setSelectedTokenId] = useState<string | undefined>();
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [claimTokenIdToConfirm, setClaimTokenIdToConfirm] = useState<bigint | undefined>();

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
      setClaimTokenIdToConfirm(firstTokenId);
      setConfirmOpen(true);
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
      setClaimTokenIdToConfirm(BigInt(tokenId));
      setConfirmOpen(true);
    },
    [],
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
    isNonNullish(effectiveTokenId) &&
    isNonNullish(subname) &&
    isNullish(subnameValidationError) &&
    isConnected &&
    chain?.id === configuredChain.id;
  const { blocksCta: availabilityBlocksCta, note: availabilityNote } =
    useClaimAvailability(shouldSimulate, subname, effectiveTokenId);

  // After successful claim, switch to "My Names" tab
  const switchedReference = useRef(false);
  useEffect(() => {
    if (isRegistered && !switchedReference.current) {
      switchedReference.current = true;
      onClaimSuccess?.();
    }
    if (!isRegistered) switchedReference.current = false;
  }, [isRegistered, onClaimSuccess]);

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

          {/* Claim confirmation */}
          <Dialog onOpenChange={setConfirmOpen} open={confirmOpen}>
            <DialogContent>
              <DialogHeader>
                <DialogTitle>Confirm claim</DialogTitle>
                <DialogDescription>
                  This will claim the chosen subname to your selected Lil Noun. A
                  transaction is required. Please review before continuing.
                </DialogDescription>
              </DialogHeader>
              <DialogFooter>
                <Button onClick={() => { setConfirmOpen(false); }} variant="secondary">
                  Cancel
                </Button>
                <Button
                  onClick={() => {
                    if (claimTokenIdToConfirm != undefined) {
                      claim(claimTokenIdToConfirm);
                    }
                    setConfirmOpen(false);
                  }}
                >
                  Confirm
                </Button>
              </DialogFooter>
            </DialogContent>
          </Dialog>
        </CardContent>
      </Card>
    </div>
  );
}
