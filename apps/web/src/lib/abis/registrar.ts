import type { Abi } from "viem";

export const registrarAbi = [
  {
    type: "function",
    name: "claimSubname",
    stateMutability: "nonpayable",
    inputs: [
      { name: "label", type: "string" },
      { name: "tokenId", type: "uint256" },
    ],
    outputs: [],
  },
] as const satisfies Abi;

