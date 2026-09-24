# Pack registry — framework-upgrade

Discover known packs and add new ones **without** renaming or forking the skill id (`framework-upgrade`).

## Known packs

| Pack id | Status | Path | Notes |
|---------|--------|------|-------|
| `angular` | **Must** — on-disk | `packs/angular/PACK.md` | Detect + `supported_range` + cascade; knowledge pointers to `_shared/angular-guidelines/` (post-upgrade quality gate) |
| `dotnet` | **Must** — on-disk | `packs/dotnet/PACK.md` | Parametric TFM/SDK (`currentVersion`→`targetVersion`); practice band 8–10; knowledge pointers to `_shared/dotnet-guidelines/` (post-upgrade quality gate) |
| `python` | Could — **future slot** (no pack dir yet) | — | Guidelines Must: `skills/_shared/python-guidelines/` + PEP 8 via `references/sources-catalog.md`; add pack via extension contract below |
| `node` | Could — not in Must | — | Add via extension contract below |
| `react` | Could — not in Must | — | Add via extension contract below |

Skill id stays **`framework-upgrade`**. Majors never enter the skill id or slash command.

## Resolve a pack

1. Read this registry for candidate ids.
2. Detect repo signals from each on-disk `packs/<id>/PACK.md` (or ask if 0 / >1 candidates).
3. Load **only** `packs/<id>/PACK.md`, then **one** `packs/<id>/references/<section>.md` per hop/step (`references/progressive-load.md`).
4. If `targetVersion` is outside pack `supported_range` → skill `references/research-protocol.md` (do not invent deltas).

## Add a pack (observable steps — REQ-014 / CT4)

Do **not** create a sibling skill (`angular-v*-upgrade`, `dotnet10-upgrade`, `framework-upgrade-vN`). New framework = new directory under this folder.

1. Create `packs/<id>/` with kebab-case stable id (e.g. `python`, `node`, `react`).
2. Write `packs/<id>/PACK.md` with at least:
   - `id`
   - detect signals (repo files / manifests)
   - `supported_range` (majors or intervals with **local** refs)
   - cascade / hops policy
   - pointer index (progressive load — no wholesale corpus paste)
3. Add curated `packs/<id>/references/` sections (index + deltas/checklists as needed). Prefer pointers into `skills/_shared/<stack>-guidelines/` over dumping bodies.
4. Add a row to the **Known packs** table above (`Status`, path, one-line notes).
5. Keep skill id `framework-upgrade`; wire only via this registry + pack load path already documented in the skill.
6. Gaps beyond `supported_range` → research protocol + optional pack PR to extend range — never a new skill id.

## Progressive load

Registry → `PACK.md` → one pack reference section → optional **one** `_shared` guideline file. Never preload every pack or guideline tree (`RNF-004` / `SR-NO-FULL-DUMP`).
