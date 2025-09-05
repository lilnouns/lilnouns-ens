Environment

- Set one of the following Vite env vars in `.env.local` to choose the chain at build time:
  - `VITE_CHAIN_ID=8453`
  - or `VITE_CHAIN_NAME=base`
- Supported names: `mainnet`, `sepolia`.
- If both are provided, `VITE_CHAIN_ID` is used.
- If neither is set, the app defaults to `mainnet` in development with a one-time console warning.

- Chain-specific RPC and Subgraph URLs:
  - RPC HTTP URL (optional, per-chain):
    - `VITE_RPC_HTTP_URL_MAINNET="https://..."`
    - `VITE_RPC_HTTP_URL_SEPOLIA="https://..."`
  - Subgraph URL (required for owned Lil Nouns, per-chain):
    - `VITE_SUBGRAPH_URL_MAINNET="https://..."`
    - `VITE_SUBGRAPH_URL_SEPOLIA="https://..."`
  - Note: The app no longer falls back to a generic `VITE_SUBGRAPH_URL` when a specific chain is selected. This prevents accidentally reading data from the wrong network.

Runbook

- Add `.env.local` with `VITE_CHAIN_ID` or `VITE_CHAIN_NAME` and, if using WalletConnect, `VITE_WC_PROJECT_ID`.
- Provide the chain-specific subgraph URL for the selected network (see above). Without it, owned Lil Nouns fall back to a local mock.
- Start dev server: `pnpm -C apps/web dev`.
- Verify the selected network by connecting a wallet; Wagmi is restricted to the configured chain only.
