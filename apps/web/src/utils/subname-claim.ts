/**
 * Choose which tokenId to use for claim simulation/submission.
 */
export function computeEffectiveTokenId(
  ownedCount: bigint | undefined,
  firstTokenId: bigint | undefined,
  selectedTokenId: string | undefined,
): bigint | undefined {
  if (ownedCount == undefined) return undefined;
  if (ownedCount == 1n && firstTokenId != undefined) return firstTokenId;
  if (ownedCount > 1 && selectedTokenId) return BigInt(selectedTokenId);
  return undefined;
}

