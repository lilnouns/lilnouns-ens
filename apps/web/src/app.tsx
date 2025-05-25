import { Button } from "@repo/ui/components/button";
import { memo } from "react";

import { CounterCard } from "@/components/counter-card";
import { NetworkCard } from "@/components/network-card";
import { useTheme } from "@/components/theme-provider";
import { WalletCard } from "@/components/wallet-card";

/**
 * Main application component
 */
function App() {
  const { theme, toggleTheme } = useTheme();

  return (
    <div className="bg-background min-h-screen">
      <header className="border-b">
        <div className="container mx-auto flex items-center justify-between p-4">
          <div className="flex items-center gap-4">
            <h1 className="text-2xl font-bold">Vite + React + shadcn/ui</h1>
          </div>
          <Button onClick={toggleTheme} variant="outline">
            {theme === "dark" ? "Light" : "Dark"} mode
          </Button>
        </div>
      </header>

      <main className="container mx-auto my-8 grid gap-6 p-4 md:grid-cols-2 lg:grid-cols-3">
        <WalletCard />
        <NetworkCard />
        <CounterCard />
      </main>
    </div>
  );
}

export default memo(App);
