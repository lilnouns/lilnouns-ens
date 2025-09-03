import * as React from "react";

import { cn } from "@repo/ui/lib/utils";

function Input({ className, ...props }: React.ComponentProps<"input">) {
  return (
    <input
      data-slot="input"
      className={cn(
        "border-input bg-background text-foreground placeholder:text-muted-foreground focus-visible:ring-ring shadow-xs flex h-9 w-full rounded-md border px-3 py-1 text-sm transition-colors focus-visible:outline-none focus-visible:ring-1 disabled:cursor-not-allowed disabled:opacity-50",
        className,
      )}
      {...props}
    />
  );
}

export { Input };

