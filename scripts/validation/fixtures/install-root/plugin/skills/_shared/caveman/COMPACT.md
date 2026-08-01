# Caveman Compact - Continuity / memory prose

Lean, optional compression of **narrative** context files so later sessions spend fewer input tokens.
Not a port of upstream `caveman-compress`. Agent-driven rewrite with **hard validators** + user `sim`.

Load only when the user asks to compact continuity/memory, or when `memory-bank-init` offers refresh-light and caveman mode is ON.

---

## In scope

| File | Notes |
|------|--------|
| `features/NNN-slug/CONTINUITY.md` | Prose sections only |
| `memory-bank/known-risks.md` | Narrative bullets |
| Other memory-bank `*.md` notes the user names | Same validators |

## Out of scope (never compact via this flow)

- PRD / PLAN / STORY / FEATURE bodies
- `tech-stack.json`, `.inventory/*`
- Source code, configs, lockfiles

---

## Process

1. Confirm target path(s). Show approximate size (lines/chars).
2. **Ask user (pt-BR):** `Posso compactar prosa em '{path}'? Backup .original.md sera criado. (sim / ajustar / cancelar)`
3. On **sim** only:
   - Copy current file to `{filename}.original.md` beside it (do not overwrite an existing `.original.md` without asking).
   - Rewrite: shorten prose; keep facts; prefer bullets; no filler.
   - Run validators (below). On any **hard fail**: restore from `.original.md`, report failure, stop.
4. Show short before/after summary (line count). Do not chain to unrelated writes.

### Rewrite rules

- Preserve document language (usually pt-BR).
- Keep heading text and heading hierarchy (same `#` / `##` titles; may drop empty fluff under a heading).
- Keep every fenced code block **byte-identical**.
- Keep every URL **identical**.
- Keep inline `` `code` `` spans identical when they denote paths, APIs, or commands.
- Do not invent abbreviations (`cfg`/`impl`) or prose arrows (`→`).
- Do not delete risk items — merge duplicates only when clearly the same fact.

---

## Validators (hard fail)

After rewrite, compare against the pre-compact snapshot (or `.original.md`):

1. **Code fences:** every ` ``` ` block body in the original appears unchanged in the new file.
2. **URLs:** every `http://` / `https://` string from the original is still present.
3. **Inline code:** every distinct `` `...` `` token from the original that looks like a path or identifier remains present.
4. **Headings:** set of heading texts (markdown ATX) must be a **superset or equal** — no renamed/removed headings without user `ajustar` approval listing the change.

Soft warn (do not auto-fail): bullet count changes by more than ~15% — tell the user and ask whether to keep.

---

## When to suggest

- CONTINUITY.md grown large after many Forma C passes
- User said `caveman on` and asks to shrink context / memory
- Step N memory refresh-light when narrative files dominate token cost

Do **not** auto-compact every session. Prefer explicit invoke.
