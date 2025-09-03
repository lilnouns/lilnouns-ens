import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@repo/ui/components/card";
import { Separator } from "@repo/ui/components/separator";
import { memo } from "react";

/**
 * Simple instructional panel displayed under the SubnameClaimCard.
 * Matches the Card look & feel from the shared UI library.
 */
function SubnameInstructionsImpl() {
  return (
    <div className="mx-auto mt-4 w-full max-w-2xl sm:mt-6">
      <Card>
        <CardHeader>
          <CardTitle>How to claim your lilnouns.eth subname</CardTitle>
          <CardDescription>
            Register a subname under lilnouns.eth that points to your wallet. Simple, transparent, and on-chain.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <ol className="text-muted-foreground list-decimal space-y-3 pl-5 text-sm">
            <li>Connect your wallet (top right). Switch networks if prompted.</li>
            <li>Choose a subname — you’ll claim <span className="font-mono">yourname.lilnouns.eth</span>.</li>
            <li>If you own multiple Lil Nouns, pick which token to use.</li>
            <li>Click “Claim” and confirm in your wallet. We’ll show progress.</li>
            <li>Done! View it on ENS, see the transaction, or copy your name.</li>
          </ol>
          <Separator className="my-4" />
          <p className="text-muted-foreground text-xs">
            Allowed: a–z, 0–9, hyphen • 3–63 chars • must start/end with a letter or number • case-insensitive.
            You need to own at least one Lil Noun to claim.
          </p>
        </CardContent>
      </Card>
    </div>
  );
}

export const SubnameInstructions = memo(SubnameInstructionsImpl);
