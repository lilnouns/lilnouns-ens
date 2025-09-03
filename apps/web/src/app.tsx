import { memo } from "react";

import { Logo } from "@/components/logo.tsx";
import { SubdomainClaimCard } from "@/components/subdomain-claim-card";
import { SubdomainInstructions } from "@/components/subdomain-instructions";
import { ThemeToggle } from "@/components/theme-toggle";
import { WalletConnectButton } from "@/components/wallet-connect-button";

/**
 * Main application component
 */
function App() {
  return (
    <div className="bg-background min-h-screen">
      <header className="border-b">
        <div
          className="container mx-auto flex flex-col items-start gap-3 p-3 sm:flex-row sm:items-center sm:justify-between sm:p-4">
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
        <SubdomainClaimCard />
        <SubdomainInstructions />
      </main>
    </div>
  );
}

export default memo(App);
