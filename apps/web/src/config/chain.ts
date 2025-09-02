import { type Chain, mainnet, sepolia } from "viem/chains";
import { z } from "zod";

import { logEnvironmentDefaultChainWarning } from "@/config/print-environment-warning";

const supportedChains: readonly Chain[] = [mainnet, sepolia] as const;
const byId = new Map<number, Chain>(supportedChains.map((c) => [c.id, c]));
const nameAliases = new Map<string, Chain>([
  ["ethereum", mainnet],
  ["mainnet", mainnet],
  ["sepolia", sepolia],
]);

function normalizeName(input: string): string {
  return input
    .trim()
    .toLowerCase()
    .replaceAll(/\s+/g, "-")
    .replaceAll("_", "-");
}

const chainIdSchema = z
  .string()
  .transform((s) => s.trim())
  .refine((s) => s.length > 0, { message: "empty id" })
  .transform(Number)
  .pipe(z.number().int().positive())
  .refine((id) => byId.has(id), {
    message: `Unsupported id. Allowed: ${[...byId.keys()].join(", ")}`,
  });

const chainNameSchema = z
  .string()
  .transform(normalizeName)
  .refine((name) => nameAliases.has(name), {
    message: `Unsupported name. Allowed: ${[...nameAliases.keys()].join(", ")}`,
  });

export function resolveChainFromEnvironmentVariables(
  rawId?: string,
  rawName?: string,
): Chain {
  if (rawId && rawId.length > 0) {
    const parsed = chainIdSchema.safeParse(rawId);
    if (!parsed.success) {
      const issue = parsed.error.issues[0]?.message ?? "Invalid VITE_CHAIN_ID";
      throw new Error(
        `[chain] Unknown VITE_CHAIN_ID="${rawId}". ${issue}. Set VITE_CHAIN_ID or VITE_CHAIN_NAME (mainnet|sepolia).`,
      );
    }
    return byId.get(parsed.data)!;
  }

  if (rawName && rawName.length > 0) {
    const parsed = chainNameSchema.safeParse(rawName);
    if (!parsed.success) {
      const issue =
        parsed.error.issues[0]?.message ?? "Invalid VITE_CHAIN_NAME";
      throw new Error(
        `[chain] Unknown VITE_CHAIN_NAME="${rawName}". ${issue}. Set VITE_CHAIN_ID or VITE_CHAIN_NAME (mainnet|sepolia).`,
      );
    }
    return nameAliases.get(normalizeName(rawName))!;
  }

  logEnvironmentDefaultChainWarning();
  return mainnet;
}

const viteChainId = (import.meta.env as { VITE_CHAIN_ID?: string })
  .VITE_CHAIN_ID;
const viteChainName = (import.meta.env as { VITE_CHAIN_NAME?: string })
  .VITE_CHAIN_NAME;

export const chain: Chain = resolveChainFromEnvironmentVariables(
  viteChainId,
  viteChainName,
);
// Narrow the chain id type to supported deployments for stronger typing in hooks
export type SupportedChainId = 11_155_111; // Extend when mainnet is supported
export const chainId: SupportedChainId = chain.id as SupportedChainId;
