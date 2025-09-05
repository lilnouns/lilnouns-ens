import { shortenAddress } from "@/utils/address";

export function HeaderDescription({
  address,
  chainName,
  isConnected,
}: Readonly<{
  address?: string;
  chainName?: string;
  isConnected: boolean;
}>) {
  if (!isConnected) return <>Connect your wallet to start.</>;
  return (
    <>
      Connected as{" "}
      <span className="font-mono">{shortenAddress(address ?? "")}</span> on{" "}
      {chainName ?? "Unknown network"}.
    </>
  );
}

