import * as React from "react";
import { cn } from "@repo/ui/lib/utils";

function Skeleton({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      data-slot="skeleton"
      className={cn("animate-pulse rounded-md bg-foreground/10 dark:bg-foreground/20", className)}
      {...props}
    />
  );
}

export { Skeleton };
