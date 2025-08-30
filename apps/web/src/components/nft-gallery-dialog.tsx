import { Button } from "@repo/ui/components/button";
import type { OwnedNft } from "@/lib/types";

type NftGalleryDialogProps = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  nfts: OwnedNft[];
  pendingTokenId?: string;
  onSelect: (tokenId: string) => void;
};

export function NftGalleryDialog({ open, onOpenChange, nfts, pendingTokenId, onSelect }: NftGalleryDialogProps) {
  if (!open) return null;
  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-label="Select a Lil Noun"
      className="fixed inset-0 z-50 flex items-center justify-center"
    >
      <div className="absolute inset-0 bg-black/50" onClick={() => onOpenChange(false)} />
      <div className="relative z-10 w-full max-w-xl rounded-lg border bg-background p-4 shadow-lg">
        <div className="mb-3">
          <h2 className="text-lg font-semibold">Select a Lil Noun</h2>
          <p className="text-muted-foreground text-sm">Choose one of your NFTs to use for claiming the subdomain.</p>
        </div>
        <div className="max-h-[50vh] overflow-auto">
          <ul className="grid grid-cols-2 gap-3 p-1 sm:grid-cols-3">
            {nfts.map((nft) => {
              const isPending = pendingTokenId === nft.tokenId;
              return (
                <li key={nft.tokenId}>
                  <button
                    type="button"
                    onClick={() => onSelect(nft.tokenId)}
                    className="group w-full overflow-hidden rounded-md border p-2 text-left outline-none focus:ring-2 focus:ring-ring focus:ring-offset-1 hover:border-primary"
                    aria-label={`Select token ${nft.name ?? `#${nft.tokenId}`}`}
                  >
                    {/* eslint-disable-next-line jsx-a11y/alt-text */}
                    <img
                      src={nft.image}
                      alt={nft.name ?? `Token #${nft.tokenId}`}
                      className="aspect-square w-full rounded object-cover"
                      loading="lazy"
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
          <Button variant="secondary" onClick={() => onOpenChange(false)}>
            Close
          </Button>
        </div>
      </div>
    </div>
  );
}

