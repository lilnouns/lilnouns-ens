import type { Address } from "viem";

import { ExternalLink } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@repo/ui/components/card";
import { Skeleton } from "@repo/ui/components/skeleton";
import { memo } from "react";
import { map, times } from "remeda";
import { useAccount } from "wagmi";

import { chainId } from "@/config/chain";
import { useReadLilNounsEnsMapperEnsNameOf } from "@/hooks/contracts";
import {
  useReadLilNounsTokenBalanceOf,
  useReadLilNounsTokenTokenOfOwnerByIndex,
} from "@nekofar/lilnouns/contracts";
import { getEnsNameHref } from "@/utils/links";

export const OwnedSubnamesList = memo(function OwnedSubnamesList() {
  const { address, isConnected } = useAccount();

  if (!isConnected || !address) return null;
  return <OwnedSubnamesInner owner={address} />;
});

function OwnedSubnameItem({
  index,
  owner,
}: Readonly<{ index: bigint; owner: Address }>) {
  const { data: tokenId, status } = useReadLilNounsTokenTokenOfOwnerByIndex({
    args: [owner, index],
    chainId,
    query: { staleTime: 60_000 },
  });

  const { data: name, isError: nameError, isLoading: nameLoading } =
    useReadLilNounsEnsMapperEnsNameOf({
      args: tokenId ? [tokenId] : undefined,
      chainId,
      query: { enabled: tokenId != null, staleTime: 60_000 },
    });

  if (status === "pending" || tokenId === undefined)
    return (
      <li className="rounded-lg border p-3">
        <Skeleton className="mb-2 h-4 w-40" />
        <Skeleton className="h-3 w-20" />
      </li>
    );

  const trimmed = (name ?? "").trim();
  if (nameLoading)
    return (
      <li className="rounded-lg border p-3">
        <div className="mb-1 text-sm font-medium">Token #{tokenId.toString()}</div>
        <Skeleton className="h-3 w-40" />
      </li>
    );

  if (nameError)
    return (
      <li className="rounded-lg border p-3">
        <div className="mb-1 text-sm font-medium">Token #{tokenId.toString()}</div>
        <div className="text-destructive text-xs">Error loading name</div>
      </li>
    );

  if (trimmed.length === 0)
    return (
      <li className="rounded-lg border p-3 text-muted-foreground">
        <div className="mb-1 text-sm font-medium">Token #{tokenId.toString()}</div>
        <div className="text-xs">No claimed subname</div>
      </li>
    );

  const href = getEnsNameHref(trimmed);
  return (
    <li className="rounded-lg border p-3">
      <div className="mb-1 text-sm font-medium">Token #{tokenId.toString()}</div>
      <a className="hover:underline text-sm" href={href} rel="noreferrer noopener" target="_blank">
        <span className="font-mono">{trimmed}</span>
        <ExternalLink aria-hidden className="ml-1 inline h-3 w-3 align-[-1px] opacity-70" />
      </a>
    </li>
  );
}

function OwnedSubnamesInner({ owner }: Readonly<{ owner: Address }>) {
  const { data: balance, isError, isLoading } = useReadLilNounsTokenBalanceOf({
    args: [owner],
    chainId,
    query: { enabled: !!owner },
  });

  const count = Number(balance ?? 0n);

  return (
    <div className="mx-auto mt-6 w-full max-w-2xl sm:mt-8">
      <Card>
        <CardHeader>
          <CardTitle className="text-lg">Your claimed subnames</CardTitle>
        </CardHeader>
        <CardContent>
          {isLoading && <SkeletonList />}
          {isError && (
            <p className="text-destructive text-sm" role="alert">
              Error loading your Lil Nouns. Please try again.
            </p>
          )}
          {!isLoading && !isError && count === 0 && (
            <p className="text-muted-foreground text-sm">
              You don't own any Lil Nouns yet.
            </p>
          )}
          {!isLoading && !isError && count > 0 && (
            <ul className="grid grid-cols-1 gap-3 sm:grid-cols-2">
              {times(count, (index) => (
                <OwnedSubnameItem index={BigInt(index)} key={`${owner}:${index}`} owner={owner} />
              ))}
            </ul>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

function SkeletonList() {
  return (
    <ul className="grid grid-cols-1 gap-3 sm:grid-cols-2">
      {map([0, 1, 2, 3], (k) => (
        <li className="rounded-lg border p-3" key={`owned-skel-${k}`}>
          <Skeleton className="mb-2 h-4 w-40" />
          <Skeleton className="h-3 w-20" />
        </li>
      ))}
    </ul>
  );
}

