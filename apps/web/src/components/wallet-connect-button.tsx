import { Button } from "@repo/ui/components/button";
import { useAccount, useChainId, useChains, useConnect, useDisconnect } from "wagmi";

import { shortenAddress } from "@/utils/address";

export function WalletConnectButton() {
  const { isConnected, address } = useAccount();
  const chainId = useChainId();
  const chains = useChains();
  const { connectors, connect, status, error, isPending } = useConnect();
  const { disconnect } = useDisconnect();

  const hasInjected = typeof window !== "undefined" && typeof (window as any).ethereum !== "undefined";

  if (!isConnected) {
    const primary = connectors.find((c) => c.id === "injected") ?? connectors[0];
    return (
      <div className="flex items-center gap-2">
        <Button
          onClick={() => primary && connect({ connector: primary })}
          disabled={!hasInjected || isPending}
          aria-busy={isPending}
          aria-label="Connect wallet"
        >
          {!hasInjected ? "Install a wallet" : status === "pending" || isPending ? "Connecting…" : "Connect Wallet"}
        </Button>
        {error ? (
          <span className="text-destructive text-sm" role="alert" aria-live="polite">
            {error.message}
          </span>
        ) : null}
      </div>
    );
  }

  const activeChainName = chains.find((c) => c.id === chainId)?.name ?? "Unknown";

  return (
    <div className="flex items-center gap-2" aria-label="Connected wallet">
      <Button variant="outline">{shortenAddress(address ?? "")} • {activeChainName}</Button>
      <Button variant="destructive" onClick={() => disconnect()} aria-label="Disconnect wallet">
        Disconnect
      </Button>
    </div>
  );
}

