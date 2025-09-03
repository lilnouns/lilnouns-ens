import * as React from "react";
import { Button } from "@repo/ui/components/button";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from "@repo/ui/components/dialog";
import { useMemo } from "react";
import { useAccount, useDisconnect, useSwitchChain } from "wagmi";

import { chain as configuredChain, chainId as configuredChainId } from "@/config/chain";

interface NetworkGuardProps {
  children: React.ReactNode;
}

export function NetworkGuard({ children }: NetworkGuardProps) {
  const { isConnected, chainId: activeChainId } = useAccount();
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
              {canProgrammaticallySwitch
                ? isPending
                  ? "Switching…"
                  : `Switch to ${configuredChain.name}`
                : "Open wallet to switch network"}
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
            ) : null}
          </div>

          <div className="mt-3 text-muted-foreground text-xs">
            <p>
              If the button doesn’t work, switch networks in your wallet to
              <span className="font-medium"> {configuredChain.name}</span> and return here.
            </p>
          </div>
        </DialogContent>
      </Dialog>
    </>
  );
}
