import { defineConfig } from "@wagmi/cli";
import { etherscan, react } from "@wagmi/cli/plugins";
import { sepolia } from "wagmi/chains";
import "dotenv/config";

export default defineConfig({
  contracts: [],
  out: "src/hooks/contracts.ts",
  plugins: [
    etherscan({
      apiKey: process.env.ETHERSCAN_API_KEY!,
      chainId: sepolia.id,
      contracts: [
        {
          address: {
            [sepolia.id]: "0x3F87314d08CF7ad9815DCBe74A0D54bbdd86d1Dc",
          },
          name: "LilNounsEnsMapper",
        },
      ],
      tryFetchProxyImplementation: true,
    }),
    react(),
  ],
});
