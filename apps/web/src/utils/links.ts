import { chain as configuredChain } from "@/config/chain";
import { lilNounsEnsMapperAddress } from "@/hooks/contracts";

/** Build block explorer contract link for the LilNounsEnsMapper. */
export function getLilNounsEnsMapperContractHref(): string | undefined {
  const explorer = configuredChain.blockExplorers?.default.url;
  const addr =
    lilNounsEnsMapperAddress[
      configuredChain.id as keyof typeof lilNounsEnsMapperAddress
    ];
  return explorer ? `${explorer}/address/${addr}` : undefined;
}

