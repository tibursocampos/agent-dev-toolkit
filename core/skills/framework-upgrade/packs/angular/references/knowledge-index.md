# Angular pack — knowledge index (pointers only)

Progressive load: cite the path and load **one** guideline file when needed. Do **not** paste guideline bodies into the upgrade session (`RNF-004` / `SR-NO-FULL-DUMP`).

## Role vs version deltas

`_shared/angular-guidelines/` are a **post-upgrade quality gate** for modes `audit` / `validate` (and selective migrate checks). They do **not** substitute pack hop / cascade version-deltas. Official angular.dev wins auxiliary gists/Medium (**RN08** — see skill `references/sources-catalog.md`).

## Shared Angular guidelines

Portable root: `skills/_shared/angular-guidelines/` (InstallRoot after sync).

| Topic | Portable path | Notes |
|-------|---------------|-------|
| Delivery checklist | `skills/_shared/angular-guidelines/checklist.md` | PR / build; Must URLs (angular.dev style-guide / signals / testing) |
| Standalone + templates | `skills/_shared/angular-guidelines/standalone-and-templates.md` | Control flow **17+**; OnPush presentational; legacy `*ngIf` match for **16** or older |
| Signals / state | `skills/_shared/angular-guidelines/signals-and-state.md` | Signals, `computed` vs `effect`, `input`/`output` |
| RxJS lifecycle | `skills/_shared/angular-guidelines/rxjs-lifecycle.md` | `takeUntilDestroyed` / async pipe / `toSignal` |
| DI / routing / forms | `skills/_shared/angular-guidelines/di-routing-forms.md` | inject, routes, reactive forms |
| Testing | `skills/_shared/angular-guidelines/testing.md` | Harnesses, zoneless-aware asserts |
| Style / structure | `skills/_shared/angular-guidelines/style-and-structure.md` | angular.dev style; not classic johnpapa as primary |

## Official sources (pointers)

| Kind | URL |
|------|-----|
| Normative | https://angular.dev/style-guide · https://angular.dev/best-practices · https://angular.dev/guide/signals |
| Catalog | `skills/framework-upgrade/references/sources-catalog.md` |

## Inventory → supported_range

| Guideline signal | Major implication |
|------------------|-------------------|
| Control flow `@if` / `@for` preferred | **17+** |
| Legacy structural directives when matching repo | **16** or older (edge) |
| Signals / signal inputs / `takeUntilDestroyed` | Modern pack (**16+** APIs; practice docs align with **17–19** band) |
| `resource` / `httpResource` | Version-gated — use only when installed major ships them |

Declared pack band: see `../PACK.md` § `supported_range`. Majors outside that band → skill `references/research-protocol.md`.
