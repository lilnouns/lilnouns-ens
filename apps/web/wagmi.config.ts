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
            [sepolia.id]: "0x6882B3C8c6E05A78d871c1525DdBe5361d9F3a93",
            [mainnet.id]: "0x39447E7177E87C11731192f955F3A5C0aA657b59",
          },
          name: "LilNounsEnsMapper",
        },
      ],
      tryFetchProxyImplementation: true,
    }),
    react(),
  ],
});
