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
            [sepolia.id]: "0xe789E1d1D0833bC93d76a258aB90DC06674948a5",
          },
          name: "Counter",
        },
      ],
      tryFetchProxyImplementation: true,
    }),
    react(),
  ],
});
