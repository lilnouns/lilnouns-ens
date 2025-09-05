import { z } from "zod";

type OptionalString = string | undefined;

const RawEnvironmentSchema = z.object({
  VITE_RPC_HTTP_URL: z.string().optional(),
  VITE_SUBGRAPH_URL: z.string().optional(),
  VITE_WC_PROJECT_ID: z.string().optional(),
});

const raw = RawEnvironmentSchema.parse(import.meta.env);

function toOptionalNonEmpty(value?: string): OptionalString {
  const v = value?.trim();
  if (!v) return undefined;
  return z.string().min(1).parse(v);
}

function toOptionalUrl(value?: string): OptionalString {
  const v = value?.trim();
  if (!v) return undefined;
  // Strict URL validation via zod
  return z.url().parse(v);
}

const resolved = {
  rpcHttpUrl: toOptionalUrl(raw.VITE_RPC_HTTP_URL),
  subgraphUrl: toOptionalUrl(raw.VITE_SUBGRAPH_URL),
  wcProjectId: toOptionalNonEmpty(raw.VITE_WC_PROJECT_ID),
} as const;

export type RuntimeEnvironment = typeof resolved;

export function getRpcHttpUrl(): RuntimeEnvironment["rpcHttpUrl"] {
  return resolved.rpcHttpUrl;
}

export function getSubgraphUrl(): RuntimeEnvironment["subgraphUrl"] {
  return resolved.subgraphUrl;
}

export function getWcProjectId(): RuntimeEnvironment["wcProjectId"] {
  return resolved.wcProjectId;
}
