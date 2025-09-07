import { defineConfig } from "@wagmi/cli";
import { etherscan, react } from "@wagmi/cli/plugins";
import { sepolia } from "wagmi/chains";
import "dotenv/config";
import { getEtherscanApiKey } from "./wagmi.env";
import { mainnet } from "viem/chains";

export default defineConfig({
  contracts: [],
  out: "src/hooks/contracts.ts",
  plugins: [
    etherscan({
      apiKey: getEtherscanApiKey(),
      chainId: sepolia.id,
      contracts: [
        {
          address: {
            [sepolia.id]: "0x20779E57C32AE340cb8671E5EafC9eB26e753D22",
            [mainnet.id]: "0x5D8E3A1991AC7d97fd813FC6367ec5c5E399A36f",
          },
          name: "LilNounsEnsMapper",
        },
      ],
      tryFetchProxyImplementation: true,
    }),
    react(),
  ],
});
