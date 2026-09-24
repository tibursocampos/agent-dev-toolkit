# Pack: angular

| Field | Value |
|-------|--------|
| **id** | `angular` |
| **Skill id** | `framework-upgrade` (never pin a major into the skill id) |
| **Status** | Must |

## Detect signals

Prefer positive hits; if 0 or >1 framework packs also match, ask once (TE03). Orchestrator flow: skill `references/detect.md`.

| Signal | Weight |
|--------|--------|
| `angular.json` at repo / workspace root (or app folder) | Strong |
| `package.json` dependencies / devDependencies include `@angular/core` or `@angular/cli` | Strong |
| `tsconfig.app.json` + `src/main.ts` bootstrap with `bootstrapApplication` / `platformBrowserDynamic` + Angular imports | Medium |
| Neighboring `nx.json` / project graph naming Angular apps | Medium (confirm which project) |

Do **not** treat generic `package.json` alone as Angular without `@angular/*`.

## Version inputs

| Input | Rule |
|-------|------|
| `currentVersion` | Installed `@angular/core` major (or CLI-reported major) |
| `targetVersion` | Desired major; **must** satisfy `target > current` |
| Semantics | Integer majors (`17`, `18`, …) unless pack refs say otherwise |

## supported_range (inventory from curated refs)

Declared from **local** curated knowledge only — not an eternal single-major lock. Gaps → research protocol (skill `references/research-protocol.md` + `sources-catalog.md` official first); **do not invent local deltas**; extend this pack later without forking the skill.

| Band | Majors | Local coverage basis |
|------|--------|----------------------|
| **In range (practice)** | **17, 18, 19** | `_shared/angular-guidelines/` targets modern standalone + control flow (**17+**), Signals / `input()` / `output()` / `takeUntilDestroyed`, testing harnesses — see `references/knowledge-index.md` |
| **Partial / edge** | **16** | Guidelines allow legacy structural-directive match for Angular 16 or older; **no** hop-delta corpus in-pack yet |
| **Out of range** | **≤15** or **≥20** (until curated) | No local hop deltas / incomplete practice map → research + TE/STOP if inventing support |

When `currentVersion`→`targetVersion` path needs a major outside the in-range band, treat the **missing major** as out of range even if endpoints are listed.

## Cascade / hops

1. Prefer **official Angular update hops** (sequential major updates via the Angular Update Guide / release notes) — do not invent multi-major “skip to latest” unless the official guide allows it for that pair.
2. One hop at a time for `migrate`: plan → operator **sim** → apply → evidence → next hop.
3. Load pack refs progressively: this `PACK.md` → **one** file under `references/` → optional **one** `_shared/angular-guidelines/*.md`.
4. Official sources: skill `references/sources-catalog.md` + pack `references/knowledge-index.md`. `_shared/angular-guidelines/` = **post-upgrade quality gate** (audit/validate) — not a version-delta substitute. RN08: angular.dev wins auxiliary.

## Progressive load index

| Need | Load |
|------|------|
| Detect / range / hops (this file) | `packs/angular/PACK.md` |
| Shared guideline pointers | `packs/angular/references/knowledge-index.md` |
| Hop / cascade detail | `packs/angular/references/cascade.md` |
| Section routing | `packs/angular/references/index.md` |

## Skip D

Honor skill `references/skip-policy.md` — no external work-item mutation, OOS product brands, or duration/effort checkpoints in this pack.
