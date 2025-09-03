import { Button } from "@repo/ui/components/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@repo/ui/components/dialog";

import type { OwnedNft } from "@/lib/types";

interface NftGalleryDialogProperties {
  nfts: OwnedNft[];
  onOpenChange: (open: boolean) => void;
  onSelect: (tokenId: string) => void;
  open: boolean;
  pendingTokenId?: string;
}

export function NftGalleryDialog({ nfts, onOpenChange, onSelect, open, pendingTokenId }: NftGalleryDialogProperties) {
  return (
    <Dialog onOpenChange={onOpenChange} open={open}>
      <DialogContent showCloseButton>
        <DialogHeader>
          <DialogTitle>Select a Lil Noun</DialogTitle>
          <DialogDescription>Choose one of your NFTs to use for claiming the subname.</DialogDescription>
        </DialogHeader>
        <div className="max-h-[50vh] overflow-auto">
          <ul className="grid grid-cols-2 gap-3 p-1 sm:grid-cols-3">
            {nfts.map((nft) => {
              const isPending = pendingTokenId === nft.tokenId;
              return (
                <li key={nft.tokenId}>
                  <button
                    aria-label={`Select token ${nft.name ?? `#${nft.tokenId}`}`}
                    className="group w-full overflow-hidden rounded-md border p-2 text-left outline-none focus:ring-2 focus:ring-ring focus:ring-offset-1 hover:border-primary"
                    onClick={() => { onSelect(nft.tokenId); }}
                    type="button"
                  >
                    {/* eslint-disable-next-line jsx-a11y/alt-text */}
                    <img
                      alt={nft.name ?? `Token #${nft.tokenId}`}
                      className="aspect-square w-full rounded object-cover"
                      loading="lazy"
                      src={nft.image}
                    />
                    <div className="mt-2 text-sm">
                      <div className="font-medium">{nft.name ?? `Lil Noun #${nft.tokenId}`}</div>
                      <div className="text-muted-foreground">Token #{nft.tokenId}</div>
                      {isPending && <div className="text-xs text-muted-foreground">Submitting…</div>}
                    </div>
                  </button>
                </li>
              );
            })}
          </ul>
        </div>
        <DialogFooter>
          <Button onClick={() => { onOpenChange(false); }} variant="secondary">
            Close
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
