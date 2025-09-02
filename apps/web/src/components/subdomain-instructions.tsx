import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@repo/ui/components/card";
import { Separator } from "@repo/ui/components/separator";
import { memo } from "react";

/**
 * Simple instructional panel displayed under the SubdomainClaimCard.
 * Matches the Card look & feel from the shared UI library.
 */
function SubdomainInstructionsImpl() {
  return (
    <div className="mx-auto mt-4 w-full max-w-2xl sm:mt-6">
      <Card>
        <CardHeader>
          <CardTitle>How to claim your Lil Nouns subname</CardTitle>
          <CardDescription>
            Follow the steps below to register a subname tied to one of your Lil Nouns NFTs.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <ol className="text-muted-foreground list-decimal space-y-3 pl-5 text-sm">
            <li>
              Connect your wallet using the button in the header. Make sure you are on the correct network
              (you will be prompted if a switch is needed).
            </li>
            <li>
              Enter your desired subname in the input field. Use only lowercase letters, numbers, and hyphens.
              It must start and end with a letter or number.
            </li>
            <li>
              If you own multiple Lil Nouns, you will be asked to choose which token to use for the claim.
            </li>
            <li>
              Click “Claim subname” and confirm the transaction in your wallet. The app will show progress while
              the transaction is pending.
            </li>
            <li>
              After confirmation, you’ll see a success message. Your new subname is now registered!
            </li>
          </ol>
          <Separator className="my-4" />
          <p className="text-muted-foreground text-xs">
            Tips: If you run into issues, ensure your wallet is connected, you own at least one Lil Noun, and
            your subname follows the validation rules. You can open the token selector at any time if you
            have multiple NFTs.
          </p>
        </CardContent>
      </Card>
    </div>
  );
}

export const SubdomainInstructions = memo(SubdomainInstructionsImpl);
