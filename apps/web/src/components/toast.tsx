import { createContext, useCallback, useContext, useMemo, useRef, useState, type PropsWithChildren } from "react";

type Toast = {
  id: string;
  title: string;
  description?: string;
  variant?: "default" | "destructive";
  duration?: number;
};

type ToastContextValue = {
  toast: (t: Omit<Toast, "id">) => void;
};

const ToastContext = createContext<ToastContextValue | undefined>(undefined);

export function ToastProvider({ children }: PropsWithChildren) {
  const [toasts, setToasts] = useState<Toast[]>([]);
  const idRef = useRef(0);

  const remove = useCallback((id: string) => {
    setToasts((ts) => ts.filter((t) => t.id !== id));
  }, []);

  const api = useMemo<ToastContextValue>(
    () => ({
      toast: ({ title, description, variant = "default", duration = 3500 }) => {
        const id = String(++idRef.current);
        const next: Toast = { id, title, description, variant, duration };
        setToasts((ts) => [...ts, next]);
        window.setTimeout(() => remove(id), duration);
      },
    }),
    [remove],
  );

  return (
    <ToastContext.Provider value={api}>
      {children}
      <div className="pointer-events-none fixed inset-0 z-50 flex flex-col items-end gap-2 p-4" aria-live="polite">
        {toasts.map((t) => (
          <div
            key={t.id}
            className={`pointer-events-auto max-w-sm rounded-md border p-3 shadow-md ${
              t.variant === "destructive" ? "border-destructive bg-destructive/10" : "bg-background"
            }`}
            role="status"
          >
            <div className="font-medium">{t.title}</div>
            {t.description ? <div className="text-muted-foreground text-sm">{t.description}</div> : null}
          </div>
        ))}
      </div>
    </ToastContext.Provider>
  );
}

export function useToast() {
  const ctx = useContext(ToastContext);
  if (!ctx) throw new Error("useToast must be used within ToastProvider");
  return ctx;
}

