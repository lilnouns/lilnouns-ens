import { chainId } from "@/config/chain";
import {
  useReadLilNounsEnsMapperName,
  useReadLilNounsEnsMapperRootLabel,
  useReadLilNounsEnsMapperRootNode,
} from "@/hooks/contracts";

/**
 * Resolve ENS root domain name via contract; fallback to lilnouns.eth.
 * Encapsulates reads for root node, name and label to keep UI presentational.
 */
export function useRootName(): string {
  const { data: rootNode } = useReadLilNounsEnsMapperRootNode({ chainId });
  const enabled = !!rootNode;
  const { data: resolved } = useReadLilNounsEnsMapperName({
    args: enabled ? [rootNode as unknown as `0x${string}`] : undefined,
    chainId,
    query: { enabled },
  });
  const { data: rootLabel } = useReadLilNounsEnsMapperRootLabel({
    chainId,
    query: { enabled },
  });
  const trimmed = (resolved ?? "").trim();
  if (trimmed.length > 0) return trimmed;
  const label = (rootLabel ?? "").trim();
  if (label.length > 0) return `${label}.eth`;
  return "lilnouns.eth";
}

