Environment

- Choose the chain at build time with one of:
  - `VITE_CHAIN_ID=1` or `11155111`
  - or `VITE_CHAIN_NAME=mainnet` or `sepolia`
- If both are provided, `VITE_CHAIN_ID` is used. If neither is set, the app defaults to `mainnet` in development with a one-time console warning.

- Unified endpoints (single set used for any chain):
  - RPC HTTP URL (optional):
    - `VITE_RPC_HTTP_URL="https://..."`
  - Subgraph URL (required for owned Lil Nouns):
    - `VITE_SUBGRAPH_URL="https://..."`
  - WalletConnect (optional):
    - `VITE_WC_PROJECT_ID="..."`

Runbook

- Add `.env.local` with `VITE_CHAIN_ID` or `VITE_CHAIN_NAME` and, if using WalletConnect, `VITE_WC_PROJECT_ID`.
- Provide the subgraph URL. Without it, owned Lil Nouns fall back to a local mock.
- Start dev server: `pnpm -C apps/web dev`.
- Verify the selected network by connecting a wallet; Wagmi is restricted to the configured chain only.
