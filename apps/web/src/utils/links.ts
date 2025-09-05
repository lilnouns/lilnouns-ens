import { chain as configuredChain } from "@/config/chain";
import { lilNounsEnsMapperAddress } from "@/hooks/contracts";
import type { Chain } from "viem";

/** Build block explorer contract link for the LilNounsEnsMapper. */
export function getLilNounsEnsMapperContractHref(): string | undefined {
  const explorer = configuredChain.blockExplorers?.default.url;
  const addr =
    lilNounsEnsMapperAddress[
      configuredChain.id as keyof typeof lilNounsEnsMapperAddress
    ];
  return explorer ? `${explorer}/address/${addr}` : undefined;
}

/** Resolve ENS App base URL and chain query param for a given chain. */
export function getEnsNameHref(name: string, opts?: { chain?: Chain }): string {
  const chain = opts?.chain ?? configuredChain;
  const isSepolia = chain?.id === 11_155_111;
  const base = isSepolia
    ? "https://sepolia.app.ens.domains"
    : "https://app.ens.domains"; // mainnet default
  return `${base}/name/${encodeURIComponent(name)}`;
}
