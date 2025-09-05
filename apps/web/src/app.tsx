import { sdk } from "@farcaster/miniapp-sdk";
import {
  Tabs,
  TabsContent,
  TabsList,
  TabsTrigger,
} from "@repo/ui/components/tabs";
import { memo, useEffect, useState } from "react";

import { Logo } from "@/components/logo.tsx";
import { OwnedSubnamesList } from "@/components/owned-subnames-list";
import { SubnameClaimCard } from "@/components/subname-claim-card";
import { SubnameInstructions } from "@/components/subname-instructions";
import { ThemeToggle } from "@/components/theme-toggle";
import { WalletConnectButton } from "@/components/wallet-connect-button";

/**
 * Main application component
 */
function App() {
  const [tab, setTab] = useState<"claim" | "owned">("claim");

  useEffect(() => {
    sdk.actions.ready().catch(() => void 0)
  }, [])

  return (
    <div className="bg-background min-h-screen">
      <header className="border-b">
        <div className="container mx-auto flex flex-col items-start gap-3 p-3 sm:flex-row sm:items-center sm:justify-between sm:p-4">
          <div className="flex items-center gap-4">
            <a
              aria-label="Lil Nouns home"
              className="focus-visible:ring-primary/50 inline-flex items-center rounded focus-visible:outline-none focus-visible:ring-2"
              href="/"
            >
              <Logo />
            </a>
          </div>
          <div className="flex w-full items-center justify-start gap-2 sm:w-auto sm:justify-end">
            <ThemeToggle />
            <WalletConnectButton />
          </div>
        </div>
      </header>

      <main className="container mx-auto my-4 p-3 sm:my-8 sm:p-4">
        <section className="mx-auto mb-6 w-full max-w-2xl text-left sm:mb-8">
          <h1 className="text-2xl font-semibold tracking-tight sm:text-3xl">
            Claim a subname under lilnouns.eth
          </h1>
          <p className="text-muted-foreground mt-2 text-sm">
            Own a Lil Noun? Mint a permanent subname that resolves to your
            wallet address. Free + gas.
          </p>
        </section>
        <div className="mx-auto w-full max-w-2xl">
          <Tabs onValueChange={(v) => { setTab(v as any); }} value={tab}>
            <TabsList className="mb-3 inline-flex min-w-full gap-2 overflow-x-auto sm:gap-3">
              <TabsTrigger
                className="data-[state=active]:bg-primary data-[state=active]:text-primary-foreground border-primary data-[state=inactive]:hover:bg-muted/50 inline-flex items-center rounded-md border px-3 py-1.5 text-sm shadow-sm"
                value="claim"
              >
                Claim
              </TabsTrigger>
              <TabsTrigger
                className="data-[state=active]:bg-primary data-[state=active]:text-primary-foreground border-primary data-[state=inactive]:hover:bg-muted/50 inline-flex items-center rounded-md border px-3 py-1.5 text-sm shadow-sm"
                value="owned"
              >
                My Names
              </TabsTrigger>
            </TabsList>
            <TabsContent value="claim">
              <SubnameClaimCard onClaimSuccess={() => setTab("owned")} />
              <SubnameInstructions />
            </TabsContent>
            <TabsContent value="owned">
              <OwnedSubnamesList />
            </TabsContent>
          </Tabs>
        </div>
      </main>
    </div>
  );
}

export default memo(App);
