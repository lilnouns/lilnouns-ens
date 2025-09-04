import { Button } from "@repo/ui/components/button";
import React from "react";

export function ClaimSection({
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
        <SuccessActions explorerBase={explorerBase} name={previewName ?? ""} txHash={txHash} />
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

function SuccessActions({
  explorerBase,
  name,
  txHash,
}: Readonly<{ explorerBase?: string; name: string; txHash?: `0x${string}` }>) {
  const [copied, setCopied] = React.useState(false);
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
        onClick={() => {
          void navigator.clipboard
            .writeText(name)
            .then(() => {
              setCopied(true);
              setTimeout(() => {
                setCopied(false);
              }, 1500);
            })
            .catch(() => {
              /* ignore */
            });
        }}
        size="sm"
        variant="ghost"
      >
        {copied ? "Copied" : "Copy name"}
      </Button>
    </div>
  );
}

