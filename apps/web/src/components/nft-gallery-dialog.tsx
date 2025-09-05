import type { Address } from "viem";

import {
  useReadLilNounsTokenBalanceOf,
  useReadLilNounsTokenTokenOfOwnerByIndex,
  useReadLilNounsTokenTokenUri,
} from "@nekofar/lilnouns/contracts";
import { Button } from "@repo/ui/components/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@repo/ui/components/dialog";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuLabel,
  DropdownMenuTrigger,
} from "@repo/ui/components/dropdown-menu";
import { Skeleton } from "@repo/ui/components/skeleton";
import { Info } from "lucide-react";
import { map, times } from "remeda";

import { chainId } from "@/config/chain";
import { useReadLilNounsEnsMapperEnsNameOf } from "@/hooks/contracts";
import { useTokenMetadata } from "@/hooks/use-token-metadata";

interface NftGalleryDialogProperties {
  onOpenChange: (open: boolean) => void;
  onSelect: (tokenId: string) => void;
  open: boolean;
  owner: Address;
  pendingTokenId?: string;
}

export function NftGalleryDialog({
  onOpenChange,
  onSelect,
  open,
  owner,
  pendingTokenId,
}: Readonly<NftGalleryDialogProperties>) {
  const {
    data: ownedCount,
    isError,
    isLoading,
  } = useReadLilNounsTokenBalanceOf({
    args: [owner],
    chainId,
  });

  return (
    <Dialog onOpenChange={onOpenChange} open={open}>
      <DialogContent showCloseButton>
        <DialogHeader>
          <DialogTitle>Select a Lil Noun</DialogTitle>
          <DialogDescription>
            Choose one of your NFTs to use for claiming the subname.
          </DialogDescription>
        </DialogHeader>
        {isLoading && (
          <div className="grid grid-cols-2 gap-3 p-1 sm:grid-cols-3">
            {map(["a", "b", "c", "d", "e", "f"] as const, (key) => (
              <div className="w-full" key={`placeholder-${key}`}>
                <Skeleton className="aspect-square w-full rounded-md" />
                <div className="mt-2 space-y-2">
                  <Skeleton className="h-3 w-3/4" />
                  <Skeleton className="h-3 w-1/2" />
                </div>
              </div>
            ))}
          </div>
        )}
        {isError && (
          <p className="text-destructive text-sm">
            Error loading your Lil Nouns. Please try again.
          </p>
        )}
        {!isLoading && !isError && (
          <div className="max-h-[50vh] overflow-auto">
            <ul className="grid grid-cols-2 gap-3 p-1 sm:grid-cols-3">
              {times(Number(ownedCount), (index) => {
                return (
                  <NftGalleryItem
                    index={BigInt(index)}
                    key={`${owner}:${String(index)}`}
                    onSelect={onSelect}
                    owner={owner}
                    pendingTokenId={pendingTokenId}
                  />
                );
              })}
            </ul>
          </div>
        )}
        <DialogFooter>
          <Button
            onClick={() => {
              onOpenChange(false);
            }}
            type="button"
            variant="secondary"
          >
            Close
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

function NftGalleryItem({
  index,
  onSelect,
  owner,
  pendingTokenId,
}: Readonly<{
  index: bigint;
  onSelect: (tokenId: string) => void;
  owner: Address;
  pendingTokenId?: string;
}>) {
  const { data: tokenId, status: idStatus } =
    useReadLilNounsTokenTokenOfOwnerByIndex({
      args: [owner, index],
      query: { staleTime: 60_000 },
    });

  const { data: tokenUri } = useReadLilNounsTokenTokenUri({
    args: tokenId ? [tokenId] : undefined,
    query: { staleTime: 60_000 },
  });

  const { data: metadata, isLoading: metadataLoading } =
    useTokenMetadata(tokenUri);

  const { data: ensName, isLoading: ensNameLoading } =
    useReadLilNounsEnsMapperEnsNameOf({
      args: tokenId ? [tokenId] : undefined,
      chainId,
      query: { enabled: tokenId != undefined, staleTime: 60_000 },
    });

  if (idStatus === "pending" || tokenId === undefined)
    return (
      <div className="flex items-center gap-3 rounded-xl border p-3">
        <Skeleton className="size-16 rounded-lg" />
        <div className="flex-1">
          <Skeleton className="mb-2 h-4 w-40" />
          <Skeleton className="h-3 w-[320px]" />
          <div className="mt-2 flex gap-1">
            <Skeleton className="h-5 w-16" />
            <Skeleton className="h-5 w-20" />
            <Skeleton className="h-5 w-14" />
          </div>
        </div>
      </div>
    );

  const image = metadata?.image ?? metadata?.animation_url;
  const name = metadata?.name ?? `Lil Noun ${tokenId.toString()}`;

  const isPending = pendingTokenId === tokenId.toString() || metadataLoading;
  const trimmedEns = (ensName ?? "").trim();
  const hasSubname = !ensNameLoading && trimmedEns.length > 0;

  return (
    <li>
      <button
        aria-label={`Select token ${name}`}
        className={`focus:ring-ring group w-full overflow-hidden rounded-md border p-2 text-left outline-none focus:ring-2 focus:ring-offset-1 ${hasSubname ? "border-primary/60" : "hover:border-primary"}`}
        onClick={() => {
          onSelect(tokenId.toString());
        }}
        type="button"
      >
        <div className="relative">
          <img
            alt={name}
            className="aspect-square w-full rounded object-cover"
            loading="lazy"
            src={image}
          />
          {hasSubname && (
            <div className="absolute right-2 top-2">
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button
                    aria-label="View subname"
                    className="h-7 w-7"
                    size="icon"
                    variant="secondary"
                  >
                    <Info className="h-4 w-4" />
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="end" className="min-w-[12rem]">
                  <DropdownMenuLabel className="text-muted-foreground text-xs">
                    Subname
                  </DropdownMenuLabel>
                  <div className="px-2 py-1.5 text-sm">
                    <span className="font-mono">{trimmedEns}</span>
                  </div>
                </DropdownMenuContent>
              </DropdownMenu>
            </div>
          )}
        </div>
        <div className="mt-2 text-sm">
          <div className="font-medium">{name}</div>
          <div className="text-muted-foreground">
            Token #{tokenId.toString()}
          </div>
          {isPending && (
            <div className="text-muted-foreground text-xs">Submitting…</div>
          )}
        </div>
      </button>
      {/* No inline subname UI below; info icon handles it */}
    </li>
  );
}
