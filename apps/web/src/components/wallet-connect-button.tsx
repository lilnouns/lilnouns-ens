import { Button } from "@repo/ui/components/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@repo/ui/components/dropdown-menu";
import { Wallet } from "lucide-react";
import { useMemo } from "react";
import { defaultTo, find } from "remeda";
import { useAccount, useConnect, useDisconnect } from "wagmi";

import {
  chain as configuredChain,
  chainId as configuredChainId,
} from "@/config/chain";
import { shortenAddress } from "@/utils/address";

interface Eip1193Provider {
  request: (request: { method: string; params?: unknown }) => Promise<unknown>;
}

export function WalletConnectButton() {
  const { address, isConnected } = useAccount();
  // Keep list if needed for future; not used currently
  // const chains = useChains();
  const { connect, connectors, error, isPending, status } = useConnect();
  const { disconnect } = useDisconnect();

  const ethereum: Eip1193Provider | undefined = (
    globalThis as unknown as { ethereum?: Eip1193Provider }
  ).ethereum;
  const hasInjected = ethereum !== undefined;

  const primary = useMemo(
    () =>
      defaultTo(
        find(connectors, (c) => c.id === "injected"),
        connectors[0],
      ),
    [connectors],
  );

  const activeChainName = configuredChain.name;

  const handleSwitchAccount = async () => {
    try {
      const eth = ethereum;
      if (!eth) return;
      // Prompt a wallet UI to manage account permissions if supported
      await eth.request({
        method: "wallet_requestPermissions",
        params: [{ eth_accounts: {} }],
      });
      await eth.request({ method: "eth_requestAccounts" });
    } catch (error_) {
      // Optional: integrate app-level toasts if desired
      console.error(error_);
    }
  };

  const canConnect =
    isConnected ||
    (hasInjected && (Boolean(primary) || connectors.length > 0)) ||
    status === "pending";

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button
          aria-busy={isPending}
          aria-label="Wallet menu"
          disabled={!canConnect}
          size="icon"
          title={
            isConnected
              ? `${shortenAddress(address ?? "")} • ${activeChainName}`
              : "Connect wallet"
          }
          variant="outline"
        >
          <Wallet className="size-5" />
          <span className="sr-only">Wallet</span>
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="w-64" side="bottom">
        {isConnected ? (
          <>
            <DropdownMenuLabel className="truncate">
              {shortenAddress(address ?? "")} • {activeChainName}
            </DropdownMenuLabel>
            <DropdownMenuSeparator />
            <DropdownMenuItem
              onClick={() => {
                void handleSwitchAccount();
              }}
            >
              Switch account…
            </DropdownMenuItem>
            <DropdownMenuItem
              className="text-destructive focus:text-destructive"
              onClick={() => {
                disconnect();
              }}
            >
              Disconnect
            </DropdownMenuItem>
          </>
        ) : (
          <>
            <DropdownMenuLabel>Connect Wallet</DropdownMenuLabel>
            <DropdownMenuSeparator />
            {connectors.map((connector) => {
              const isInjected = connector.id === "injected";
              const available = !isInjected || hasInjected;
              return (
                <DropdownMenuItem
                  aria-disabled={!available || isPending}
                  className={available ? "" : "opacity-50"}
                  key={connector.id}
                  onClick={() => {
                    // Force connect to the configured chain
                    connect({ chainId: configuredChainId, connector });
                  }}
                >
                  {connector.name}
                  {available ? "" : " (unavailable)"}
                </DropdownMenuItem>
              );
            })}
            {!hasInjected && (
              <div className="text-muted-foreground px-2 py-1 text-sm">
                No injected wallet detected
              </div>
            )}
            {error ? (
              <div
                aria-live="polite"
                className="text-destructive px-2 py-1 text-sm"
                role="alert"
              >
                {error.message}
              </div>
            ) : undefined}
          </>
        )}
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
