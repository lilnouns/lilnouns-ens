import { Button } from "@repo/ui/components/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@repo/ui/components/dialog";
import * as React from "react";
import { useMemo } from "react";
import { useAccount, useDisconnect, useSwitchChain } from "wagmi";

import {
  chain as configuredChain,
  chainId as configuredChainId,
} from "@/config/chain";

interface NetworkGuardProperties {
  children: React.ReactNode;
}

export function NetworkGuard({ children }: Readonly<NetworkGuardProperties>) {
  const { chainId: activeChainId, isConnected } = useAccount();
  const { disconnect } = useDisconnect();
  const { chains, error, isPending, switchChain } = useSwitchChain();

  const isWrongNetwork = useMemo(() => {
    if (!isConnected) return false;
    if (!activeChainId) return true;
    return activeChainId !== configuredChainId;
  }, [isConnected, activeChainId]);

  const canProgrammaticallySwitch = useMemo(
    () => chains.some((c) => c.id === configuredChainId),
    [chains],
  );

  const switchButtonLabel = useMemo(() => {
    if (!canProgrammaticallySwitch) {
      return "Open wallet to switch network";
    }
    return isPending ? "Switching…" : `Switch to ${configuredChain.name}`;
  }, [canProgrammaticallySwitch, isPending]);

  return (
    <>
      {children}
      <Dialog open={isWrongNetwork}>
        <DialogContent showCloseButton={false}>
          <DialogHeader>
            <DialogTitle>Wrong network</DialogTitle>
            <DialogDescription>
              You are connected to an unsupported network. This app requires
              <span className="font-medium"> {configuredChain.name}</span>.
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-2">
            <Button
              aria-busy={isPending}
              className="w-full"
              disabled={isPending || !canProgrammaticallySwitch}
              onClick={() => {
                try {
                  switchChain({ chainId: configuredChainId });
                } catch {
                  // noop
                }
              }}
            >
              {switchButtonLabel}
            </Button>

            <Button
              className="w-full"
              onClick={() => {
                disconnect();
              }}
              variant="secondary"
            >
              Disconnect
            </Button>

            {error ? (
              <p className="text-destructive text-sm" role="alert">
                {error.message}
              </p>
            ) : undefined}
          </div>

          <div className="text-muted-foreground mt-3 text-xs">
            <p>
              If the button doesn’t work, switch networks in your wallet to
              <span className="font-medium"> {configuredChain.name}</span> and
              return here.
            </p>
          </div>
        </DialogContent>
      </Dialog>
    </>
  );
}
