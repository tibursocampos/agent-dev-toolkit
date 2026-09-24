# Dotnet pack — plan contract (parametric versions)

## Purpose

Define how `plan` / `migrate` resolve version pairs for pack `dotnet` without pinning the skill id to a major.

## Inputs

| Field | Constraint |
|-------|------------|
| `framework_id` | `dotnet` |
| `currentVersion` | Integer major (from TFM / SDK); required when versions apply |
| `targetVersion` | Integer major; **must** be `>` `currentVersion` (RN07) |
| Skill id | `framework-upgrade` only |

Reject equal or downgrade targets. Ask once if either version is missing or ambiguous (multiple TFMs).

## Pair policy

1. Accept **any** in-range pair with `target > current` (not a single hardcoded hop such as “only 8→10”).
2. Multi-major spans (e.g. `8→10`) → decompose into sequential hops unless official guidance documents a direct path.
3. If any required hop major is outside `../PACK.md` `supported_range` → skill `references/research-protocol.md`; do not invent deltas.
4. Future majors (e.g. 11+) enter via pack `supported_range` extension + curated refs — **never** `framework-upgrade-vN` or `dotnet{N}-upgrade`.

## Plan output (minimal)

- Detected signals + resolved majors
- Hop list (`current` → … → `target`)
- In-range vs research gaps
- Pointers to **one** compatibility / validation / knowledge section as needed (progressive load)

Do not paste Learn articles, release notes, or `_shared` guideline bodies into the plan.
