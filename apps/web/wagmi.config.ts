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
            [sepolia.id]: "0x20779e57c32ae340cb8671e5eafc9eb26e753d22",
            [mainnet.id]: "0x5d8e3a1991ac7d97fd813fc6367ec5c5e399a36f",
          },
          name: "LilNounsEnsMapper",
        },
      ],
      tryFetchProxyImplementation: true,
    }),
    react(),
  ],
});
