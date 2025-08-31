import { Button } from "@repo/ui/components/button";

import type { OwnedNft } from "@/lib/types";

interface NftGalleryDialogProperties {
  nfts: OwnedNft[];
  onOpenChange: (open: boolean) => void;
  onSelect: (tokenId: string) => void;
  open: boolean;
  pendingTokenId?: string;
}

export function NftGalleryDialog({ nfts, onOpenChange, onSelect, open, pendingTokenId }: NftGalleryDialogProperties) {
  if (!open) return null;
  return (
    <div
      aria-label="Select a Lil Noun"
      aria-modal="true"
      className="fixed inset-0 z-50 flex items-center justify-center"
      role="dialog"
    >
      <div className="absolute inset-0 bg-black/50" onClick={() => { onOpenChange(false); }} />
      <div className="relative z-10 w-full max-w-xl rounded-lg border bg-background p-4 shadow-lg sm:p-6">
        <div className="mb-3">
          <h2 className="text-lg font-semibold">Select a Lil Noun</h2>
          <p className="text-muted-foreground text-sm">Choose one of your NFTs to use for claiming the subname.</p>
        </div>
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
        <div className="mt-4 flex justify-end gap-2">
          <Button onClick={() => { onOpenChange(false); }} variant="secondary">
            Close
          </Button>
        </div>
      </div>
    </div>
  );
}
