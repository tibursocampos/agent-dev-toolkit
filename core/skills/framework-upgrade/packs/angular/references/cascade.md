# Angular pack — cascade / hops

## Policy

1. Resolve `currentVersion` and `targetVersion` (majors); require `target > current`.
2. If any required hop major is outside `supported_range` in `../PACK.md` → stop inventing; use skill `references/research-protocol.md`.
3. Prefer **sequential official hops** (n → n+1) unless the official Angular Update Guide documents a supported multi-major path for that pair.
4. For `migrate`: one hop per approval cycle (plan summary → operator **sim** → apply → evidence → next).

## Local vs official

| Source | Role |
|--------|------|
| This pack + `knowledge-index.md` | Practice / template / Signals / testing rules for in-range majors |
| Angular Update Guide / release notes (official) | Normative breaking changes and schematic steps per hop |

Do not dump Update Guide HTML or third-party upgrade blogs into pack files. Pointers and short hop notes only; deepen official cites in a later PLAN step.

## Example path (illustrative)

`17 → 19` with both ends in range: plan hops `17→18`, then `18→19`; load **one** guideline file per touching concern — not the whole guidelines folder.
