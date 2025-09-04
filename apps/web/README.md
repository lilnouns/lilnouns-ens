Environment

- Set one of the following Vite env vars in `.env.local` to choose the chain at build time:
  - `VITE_CHAIN_ID=8453`
  - or `VITE_CHAIN_NAME=base`
- Supported names: `mainnet`, `sepolia`.
- If both are provided, `VITE_CHAIN_ID` is used.
- If neither is set, the app defaults to `mainnet` in development with a one-time console warning.

Runbook

- Add `.env.local` with `VITE_CHAIN_ID` or `VITE_CHAIN_NAME` and, if using WalletConnect, `VITE_WC_PROJECT_ID`.
- Start dev server: `pnpm -C apps/web dev`.
- Verify the selected network by connecting a wallet; Wagmi is restricted to the configured chain only.
