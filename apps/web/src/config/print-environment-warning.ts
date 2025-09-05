let warned = false;

export function logEnvironmentDefaultChainWarning(): void {
  if (warned) return;
  // Only warn during development to avoid noisy production logs.
  if (import.meta.env.DEV) {
    console.warn(
      "[chain] VITE_CHAIN_ID/VITE_CHAIN_NAME not set; defaulting to mainnet (1)",
    );
  }
  warned = true;
}
