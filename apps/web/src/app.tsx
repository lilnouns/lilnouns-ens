import { memo } from "react";

import { SubdomainClaimCard } from "@/components/subdomain-claim-card";
import { ThemeToggle } from "@/components/theme-toggle";
import { WalletConnectButton } from "@/components/wallet-connect-button";

/**
 * Main application component
 */
function App() {
  return (
    <div className="bg-background min-h-screen">
      <header className="border-b">
        <div className="container mx-auto flex flex-col items-start gap-3 p-3 sm:flex-row sm:items-center sm:justify-between sm:p-4">
          <div className="flex items-center gap-4">
            <h1 className="text-lg font-bold sm:text-2xl">Lil Nouns</h1>
          </div>
          <div className="flex w-full items-center justify-start gap-2 sm:w-auto sm:justify-end">
            <ThemeToggle />
            <WalletConnectButton />
          </div>
        </div>
      </header>

      <main className="container mx-auto my-4 p-3 sm:my-8 sm:p-4">
        <SubdomainClaimCard />
      </main>
    </div>
  );
}

export default memo(App);
