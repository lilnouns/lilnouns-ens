import { Skeleton } from "@repo/ui/components/skeleton";
import { isNonNullish, isNullish } from "remeda";

export function OwnershipStatus({
  isConnected,
  mustChooseToken,
  ownedCount,
}: Readonly<{
  isConnected: boolean;
  mustChooseToken: boolean;
  ownedCount: bigint | undefined;
}>) {
  return (
    <div aria-live="polite" className="text-muted-foreground mb-4 text-sm" role="status">
      {isConnected && isNonNullish(ownedCount) && `Owned Lil Nouns: ${ownedCount.toString()}`}
      {mustChooseToken && isNullish(ownedCount) && (
        <div className="mt-2">
          <Skeleton className="h-3 w-40" />
        </div>
      )}
      {mustChooseToken && isNullish(ownedCount) && "Error loading Lil Nouns list."}
    </div>
  );
}

