import { Input } from "@repo/ui/components/input";
import { Label } from "@repo/ui/components/label";

export function NameInputWithSuffix({
  onBlurValidate,
  onChange,
  previewName,
  rootName,
  subname,
  subnameError,
}: Readonly<{
  onBlurValidate: () => void;
  onChange: (v: string) => void;
  previewName?: string;
  rootName: string;
  subname: string;
  subnameError?: string;
}>) {
  return (
    <>
      <Label className="text-sm" htmlFor="subname">
        Choose a subname
      </Label>
      <div>
        <div className="relative">
          <Input
            aria-invalid={!!subnameError}
            aria-label="Subname label"
            autoComplete="off"
            id="subname"
            inputMode="text"
            onBlur={onBlurValidate}
            onChange={(event) => {
              onChange(event.target.value);
            }}
            placeholder="yourname"
            type="text"
            value={subname}
          />
          <span
            aria-hidden="true"
            className="text-muted-foreground pointer-events-none absolute inset-y-0 right-3 flex items-center text-sm"
          >
            .{rootName}
          </span>
        </div>
        <p className="text-muted-foreground mt-1 text-xs">
          Allowed: a–z, 0–9, hyphen • 3–63 chars • case-insensitive
        </p>
        {previewName && (
          <p className="mt-1 text-sm">
            Preview: <span className="font-mono">{previewName}</span>
          </p>
        )}
      </div>
      {subnameError ? (
        <p className="text-destructive text-sm">{subnameError}</p>
      ) : undefined}
    </>
  );
}

