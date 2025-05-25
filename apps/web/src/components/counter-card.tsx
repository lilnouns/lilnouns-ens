import { Button } from "@repo/ui/components/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@repo/ui/components/card";
import { useCallback, useEffect, useState } from "react";
import { useWatchBlocks } from "wagmi";

import {
  useReadCounterNumber,
  useWriteCounterIncrement,
  useWriteCounterSetNumber,
} from "@/hooks/contracts";

export function CounterCard() {
  const [count, setCount] = useState(0);

  const { data: counterNumber, refetch: refetchCounterNumber } =
    useReadCounterNumber({});
  const { writeContract: setCounterNumber } = useWriteCounterSetNumber();
  const { writeContract: increaseCounterNumber } = useWriteCounterIncrement();

  // Update the UI when the contract value changes
  useEffect(() => {
    const currentCount = Number(counterNumber ?? 0n);
    if (count !== currentCount) {
      setCount(currentCount);
    }
  }, [counterNumber, count]);

  // Watch for blocks and refresh counter value
  useWatchBlocks({
    onBlock: () => {
      void refetchCounterNumber();
    },
  });

  const handleDecrement = useCallback(() => {
    setCounterNumber({ args: [BigInt(Math.max(1, count - 1))] });
    void refetchCounterNumber();
  }, [count, setCounterNumber, refetchCounterNumber]);

  const handleIncrement = useCallback(() => {
    setCounterNumber({ args: [BigInt(count + 1)] });
    void refetchCounterNumber();
  }, [count, setCounterNumber, refetchCounterNumber]);

  const handleIncrementContract = useCallback(() => {
    increaseCounterNumber({});
    void refetchCounterNumber();
  }, [increaseCounterNumber, refetchCounterNumber]);

  return (
    <Card>
      <CardHeader>
        <CardTitle>Counter Demo</CardTitle>
        <CardDescription>Test HMR with state updates</CardDescription>
      </CardHeader>
      <CardContent className="flex flex-col items-center justify-center space-y-4">
        <div className="flex items-center gap-2">
          <Button
            disabled={count === 0}
            onClick={handleDecrement}
            size="icon"
            variant="outline"
          >
            -
          </Button>
          <span className="min-w-10 text-center text-2xl font-bold">
            {count}
          </span>
          <Button onClick={handleIncrement} size="icon" variant="outline">
            +
          </Button>
        </div>
        <Button onClick={handleIncrementContract}>Increment</Button>
      </CardContent>
    </Card>
  );
}
