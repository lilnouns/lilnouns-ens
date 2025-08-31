import { createContext, type PropsWithChildren, use, useCallback, useMemo, useRef, useState } from "react";

interface Toast {
  description?: string;
  duration?: number;
  id: string;
  title: string;
  variant?: "default" | "destructive";
}

interface ToastContextValue {
  toast: (t: Omit<Toast, "id">) => void;
}

const ToastContext = createContext<ToastContextValue | undefined>(undefined);

export function ToastProvider({ children }: PropsWithChildren) {
  const [toasts, setToasts] = useState<Toast[]>([]);
  const idReference = useRef(0);

  const remove = useCallback((id: string) => {
    setToasts((ts) => ts.filter((t) => t.id !== id));
  }, []);

  const api = useMemo<ToastContextValue>(
    () => ({
      toast: ({ description, duration = 3500, title, variant = "default" }) => {
        const id = String(++idReference.current);
        const next: Toast = { description, duration, id, title, variant };
        setToasts((ts) => [...ts, next]);
        globalThis.setTimeout(() => { remove(id); }, duration);
      },
    }),
    [remove],
  );

  return (
    <ToastContext value={api}>
      {children}
      <div aria-live="polite" className="pointer-events-none fixed inset-0 z-50 flex flex-col items-end gap-2 p-4">
        {toasts.map((t) => (
          <div
            className={`pointer-events-auto max-w-sm rounded-md border p-3 shadow-md ${
              t.variant === "destructive" ? "border-destructive bg-destructive/10" : "bg-background"
            }`}
            key={t.id}
            role="status"
          >
            <div className="font-medium">{t.title}</div>
            {t.description ? <div className="text-muted-foreground text-sm">{t.description}</div> : null}
          </div>
        ))}
      </div>
    </ToastContext>
  );
}

export function useToast() {
  const context = use(ToastContext);
  if (!context) throw new Error("useToast must be used within ToastProvider");
  return context;
}

