import {
  createContext,
  type ReactNode,
  use,
  useCallback,
  useEffect,
  useMemo,
  useState,
} from "react";

/**
 * Theme type definition
 */
export type Theme = "dark" | "light";

/**
 * Theme context properties interface
 */
interface ThemeContextProperties {
  theme: Theme;
  toggleTheme: () => void;
}

/**
 * Context for providing theme state and toggle function
 */
const ThemeContext = createContext<ThemeContextProperties | undefined>(
  undefined,
);
ThemeContext.displayName = "ThemeContext";

/**
 * Theme provider component
 */
export function ThemeProvider({ children }: Readonly<{ children: ReactNode }>) {
  const [theme, setTheme] = useState<Theme>(getInitialTheme);

  // Apply theme to document and persist in localStorage
  useEffect(() => {
    document.documentElement.classList.remove("dark", "light");
    document.documentElement.classList.add(theme);
    localStorage.setItem("theme", theme);
  }, [theme]);

  // Memoize the toggle function to prevent recreation on each render
  const toggleTheme = useCallback(() => {
    setTheme((previous) => (previous === "dark" ? "light" : "dark"));
  }, []);

  // Memoize the context value to prevent unnecessary rerenders
  const contextValue = useMemo(() => ({ theme, toggleTheme }), [theme, toggleTheme]);

  return (
    <ThemeContext value={contextValue}>
      {children}
    </ThemeContext>
  );
}

/**
 * Hook to access the theme context
 * @throws Error if used outside ThemeProvider
 */
export function useTheme() {
  const context = use(ThemeContext);
  if (!context) throw new Error("useTheme must be used inside ThemeProvider");
  return context;
}

/**
 * Gets the initial theme based on local storage or system preference
 */
function getInitialTheme(): Theme {
  if ("window" in globalThis) {
    const saved = globalThis.localStorage.getItem("theme") as null | Theme;
    if (saved) return saved;

    return globalThis.matchMedia("(prefers-color-scheme: dark)").matches
      ? "dark"
      : "light";
  }

  // Default for SSR
  return "light";
}
