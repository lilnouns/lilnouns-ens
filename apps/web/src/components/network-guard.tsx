import { Button } from "@repo/ui/components/button";
import { useEffect, useMemo, useRef, useState } from "react";
import { useAccount, useDisconnect, useSwitchChain } from "wagmi";

import { chain as configuredChain, chainId as configuredChainId } from "@/config/chain";

interface NetworkGuardProps {
  children: React.ReactNode;
}

export function NetworkGuard({ children }: NetworkGuardProps) {
  const { isConnected, chainId: activeChainId, status } = useAccount();
  const { disconnect } = useDisconnect();
  const { chains, error, isPending, switchChain } = useSwitchChain();

  const [dialogOpen, setDialogOpen] = useState(false);
  const lastMismatchRef = useRef(false);

  const isWrongNetwork = useMemo(() => {
    if (!isConnected) return false;
    if (!activeChainId) return true;
    return activeChainId !== configuredChainId;
  }, [isConnected, activeChainId]);

  useEffect(() => {
    if (isWrongNetwork && !dialogOpen) setDialogOpen(true);
    if (!isWrongNetwork && dialogOpen) setDialogOpen(false);
    lastMismatchRef.current = isWrongNetwork;
  }, [isWrongNetwork, dialogOpen]);

  const canProgrammaticallySwitch = useMemo(
    () => chains.some((c) => c.id === configuredChainId),
    [chains],
  );

  return (
    <div className="relative">
      {/* Render the app content. If wrong network, hide from assistive tech and disable interaction. */}
      <div aria-hidden={isWrongNetwork} inert={isWrongNetwork as any}>
        {children}
      </div>

      {isWrongNetwork && dialogOpen && (
        <div
          aria-label="Wrong network"
          aria-modal="true"
          className="fixed inset-0 z-50 flex items-center justify-center"
          role="dialog"
        >
          <div className="absolute inset-0 bg-black/50" />
          <div className="relative z-10 w-full max-w-md rounded-lg border bg-background p-4 shadow-lg sm:p-6">
            <div className="mb-4 space-y-1">
              <h2 className="text-lg font-semibold">Wrong network</h2>
              <p className="text-muted-foreground text-sm">
                You are connected to an unsupported network. This app requires
                <span className="font-medium"> {configuredChain.name}</span>.
              </p>
            </div>

            <div className="space-y-2">
              <Button
                aria-busy={isPending}
                className="w-full"
                disabled={isPending || !canProgrammaticallySwitch}
                onClick={() => {
                  try {
                    switchChain({ chainId: configuredChainId });
                  } catch {
                    // noop – UI already guides the user
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
                {" "}
                <span className="font-medium">{configuredChain.name}</span> and return here.
              </p>
            </div>
          </div>
        </div>
      )}

      {/* Screen-level overlay to block pointer events with a subtle hint */}
      {isWrongNetwork && (
        <div className="pointer-events-none fixed inset-0 z-40 backdrop-blur-[1px]" />
      )}
    </div>
  );
}

