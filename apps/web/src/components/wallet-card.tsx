import { Badge } from "@repo/ui/components/badge";
import { Button } from "@repo/ui/components/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@repo/ui/components/card";
import { useAccount, useConnect, useDisconnect } from "wagmi";

import { shortenAddress } from "@/utils/address";

export function WalletCard() {
  const account = useAccount();
  const { connect, connectors, error } = useConnect();
  const { disconnect } = useDisconnect();

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          Wallet
          {account.isConnected && (
            <Badge className="ml-2" variant="outline">
              Connected
            </Badge>
          )}
        </CardTitle>
        <CardDescription>
          Connect your wallet to interact with the dApp
        </CardDescription>
      </CardHeader>
      <CardContent>
        {account.isConnected ? (
          <div className="space-y-4">
            <div className="grid gap-1">
              <div className="flex justify-between">
                <span className="text-muted-foreground">Status:</span>
                <span className="font-medium">{account.status}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Address:</span>
                <span className="font-medium">
                  {account.addresses
                    ?.map((addr) => shortenAddress(addr))
                    .join(", ") ?? "Not available"}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Chain ID:</span>
                <span className="font-medium">{account.chainId}</span>
              </div>
            </div>
          </div>
        ) : (
          <div className="grid gap-4">
            <p className="text-muted-foreground text-sm">
              Connect with one of the available wallet providers:
            </p>
            <div className="flex flex-wrap gap-2">
              {connectors.map((connector) => (
                <Button
                  className="min-w-24 flex-1"
                  key={connector.uid}
                  onClick={() => {
                    connect({ connector });
                  }}
                  variant="outline"
                >
                  {connector.name}
                </Button>
              ))}
            </div>
            {error && (
              <p className="text-destructive bg-destructive/10 rounded-md p-2 text-sm">
                {error.message}
              </p>
            )}
          </div>
        )}
      </CardContent>
      {account.isConnected && (
        <CardFooter className="flex justify-end pt-0">
          <Button
            onClick={() => {
              disconnect();
            }}
            variant="destructive"
          >
            Disconnect
          </Button>
        </CardFooter>
      )}
    </Card>
  );
}
