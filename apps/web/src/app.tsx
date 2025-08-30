import { Button } from "@repo/ui/components/button";
import { memo } from "react";

import { SubdomainClaimCard } from "@/components/subdomain-claim-card";
import { useTheme } from "@/components/theme-provider";

/**
 * Main application component
 */
function App() {
  const { theme, toggleTheme } = useTheme();

  return (
    <div className="bg-background min-h-screen">
      <header className="border-b">
        <div className="container mx-auto flex flex-col items-start gap-3 p-4 sm:flex-row sm:items-center sm:justify-between">
          <div className="flex items-center gap-4">
            <h1 className="text-xl font-bold sm:text-2xl">Lil Nouns ENS</h1>
          </div>
          <Button onClick={toggleTheme} variant="outline" className="w-full sm:w-auto">
            {theme === "dark" ? "Light" : "Dark"} mode
          </Button>
        </div>
      </header>

      <main className="container mx-auto my-6 p-4 sm:my-8">
        <SubdomainClaimCard />
      </main>
    </div>
  );
}

export default memo(App);
