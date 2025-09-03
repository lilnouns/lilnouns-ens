import { Toaster } from "sonner";

import { useTheme } from "@/components/theme-provider";

export function AppToaster() {
  const { theme } = useTheme();
  return (
    <Toaster closeButton duration={3500} position="top-right" theme={theme} />
  );
}
