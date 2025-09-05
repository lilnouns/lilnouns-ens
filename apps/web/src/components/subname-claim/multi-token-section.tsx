import type { Address } from "viem";

import { Button } from "@repo/ui/components/button";
import { Separator } from "@repo/ui/components/separator";

import { NftGalleryDialog } from "@/components/nft-gallery-dialog";

export function MultiTokenSection({
  address,
  dialogOpen,
  onOpenChange,
  onOpenDialog,
  onTokenSelect,
  pendingTokenId,
  shouldShow,
}: Readonly<{
  address?: Address;
  dialogOpen: boolean;
  onOpenChange: (open: boolean) => void;
  onOpenDialog: () => void;
  onTokenSelect: (tokenId: string) => void;
  pendingTokenId?: string;
  shouldShow: boolean;
}>) {
  if (!shouldShow || !address) return ;
  return (
    <>
      <Separator className="my-6" />
      <div className="flex flex-col items-start justify-between gap-2 sm:flex-row sm:items-center">
        <p className="text-muted-foreground text-sm">
          You have multiple Lil Nouns. Choose which to use.
        </p>
        <Button onClick={onOpenDialog} variant="secondary">
          Open selector
        </Button>
      </div>
      <NftGalleryDialog
        onOpenChange={onOpenChange}
        onSelect={onTokenSelect}
        open={dialogOpen}
        owner={address}
        pendingTokenId={pendingTokenId}
      />
    </>
  );
}

