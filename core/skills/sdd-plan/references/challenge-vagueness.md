## Challenge vagueness (Aceite + step titles)

Before finalizing steps: rewrite Aceite lines that say "works", "ok", "as expected", "funciona", "como esperado". Prefer observable checks (tests named, script exit, checklist item).

### Non-vague Aceite (required)

Every step **Aceite** must:

1. Cite at least one **REQ-NNN** and/or **CA** from the PRD.
2. State a **verifiable** outcome (named test, script exit code, checklist item, or measurable behavior) — not "done", "ok", or "implementado".
3. Map to Prior context when present: **cite** portable paths to story `ARCH/` and/or `ANALYSIS/` (and SEC when relevant) instead of pasting bodies (`SELECTIVE-RETRIEVAL.md` / `SR-NO-FULL-DUMP`).

### Anti file-named steps

Step titles and Aceite must **not** be only a file, class, script, or path name.

| Forbidden (file-named / task-shaped) | Prefer (behavior / outcome) |
|--------------------------------------|-----------------------------|
| "`OrderValidator.cs`" | "Validate empty optional field on create-order command" |
| "Add `validate-foo.ps1`" | "Fail Assert when fixture FEATURE omits Goals" |
| "Update Application layer" | "Expose export-by-date API with authorization check" |

Lazy-load when sizing or rewriting titles: `story-sizing.md` (step title ≠ file/class only) and `anti-task-shatter.md` (verb+file/class/script stays a task under an outcome step — do not invent a US-shaped PLAN step per file). Checklist: `references/baby-step-sizing.md`.
