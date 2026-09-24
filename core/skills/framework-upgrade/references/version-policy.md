# Version policy — framework-upgrade

Orchestrator contract. Concrete ranges live in each `packs/<id>/PACK.md`.

## Skill id

Always `framework-upgrade`. Version majors **never** enter the skill id or slash command.

## Resolve order

1. **`framework_id`** — load `references/detect.md` (REQ-010 / TE03). Pack signals in `packs/<id>/PACK.md`.
2. **Versions** — validate pair below.
3. **Range** — compare to pack `supported_range`; out of range → `references/research-protocol.md` (REQ-012 / TE04).

## Inputs

| Input | Rule |
|-------|------|
| `framework_id` | Pack id (`angular`, `dotnet`, …) — detect or ask per `detect.md` |
| `currentVersion` | Semantic version / major understood by the pack |
| `targetVersion` | Semantic; **must** satisfy `target > current` |
| `supported_range` | Declared in `packs/<id>/PACK.md` (PASSO 6–7 inventory — do not invent wider bands in-session) |

## In range

- Follow pack cascade / hops (e.g. Angular official hops; .NET TFM/SDK parametric path).
- Do **not** hardcode a single pair (e.g. “only 8→10”) in this orchestrator.
- Practice / partial / out bands are pack-owned; treat **missing hop majors** as out of range even if endpoints are listed.

## Out of range (TE04)

- Load `references/research-protocol.md` (reuses `sources-catalog.md` — official first).
- **Forbidden:** invent local deltas / widen `supported_range` without research + pack PR.
- Operator insists on migrate without evidence → **TE04 STOP**.
- Optional after research: propose extending the pack’s `supported_range` (pack PR) — **not** a new skill.

## Pack availability

- Discover ids in `packs/REGISTRY.md`; load `packs/<id>/PACK.md` for range.
- On-disk Must: `angular` (practice **17–19**; partial **16**; out ≤15 / ≥20), `dotnet` (practice **8–10**; partial **6–7**; out ≤5 / ≥11) — align with pack inventory; do not invent majors beyond these without research.
- Could packs land via registry extension — no skill rename.
- `migrate` **STOP** if no pack `PACK.md` is available for the resolved id.
- `audit` / `plan` may record “pack not on disk” gaps without inventing deltas.

## Migrate gate (TE05)

Out-of-range research does **not** authorize mutate. `migrate` still requires explicit operator **sim**; silence ≠ approval.
