import { Badge } from "@repo/ui/components/badge";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@repo/ui/components/card";
import { useBlockNumber } from "wagmi";

export function NetworkCard() {
  const { data: blockNumber } = useBlockNumber({
    watch: true,
  });

  return (
    <Card>
      <CardHeader>
        <CardTitle>Network</CardTitle>
        <CardDescription>Current blockchain network status</CardDescription>
      </CardHeader>
      <CardContent>
        <div className="flex items-center justify-between py-2">
          <span className="text-muted-foreground">Latest block:</span>
          <Badge className="animate-pulse bg-green-500/10" variant="secondary">
            {blockNumber ? blockNumber.toLocaleString() : "..."}
          </Badge>
        </div>
      </CardContent>
    </Card>
  );
}
