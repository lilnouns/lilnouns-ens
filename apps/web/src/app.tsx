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
        <div className="container mx-auto flex items-center justify-between p-4">
          <div className="flex items-center gap-4">
            <h1 className="text-2xl font-bold">Lil Nouns ENS</h1>
          </div>
          <Button onClick={toggleTheme} variant="outline">
            {theme === "dark" ? "Light" : "Dark"} mode
          </Button>
        </div>
      </header>

      <main className="container mx-auto my-8 p-4">
        <SubdomainClaimCard />
      </main>
    </div>
  );
}

export default memo(App);
