import { z } from "zod";

const EnvSchema = z.object({
  ETHERSCAN_API_KEY: z
    .string()
    .min(1, "ETHERSCAN_API_KEY is required for wagmi codegen"),
});

export function getEtherscanApiKey(): string {
  const parsed = EnvSchema.safeParse(process.env);
  if (!parsed.success) {
    const msg = parsed.error.issues[0]?.message ?? "Missing ETHERSCAN_API_KEY";
    throw new Error(`[wagmi.env] ${msg}`);
  }
  return parsed.data.ETHERSCAN_API_KEY;
}

