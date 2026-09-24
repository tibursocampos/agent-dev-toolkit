# Pack: dotnet

| Field | Value |
|-------|--------|
| **id** | `dotnet` |
| **Skill id** | `framework-upgrade` (never pin a major into the skill id) |
| **Status** | Must |

## Detect signals

Prefer positive hits; if 0 or >1 framework packs also match, ask once (TE03). Orchestrator flow: skill `references/detect.md`.

| Signal | Weight |
|--------|--------|
| `*.sln` / `*.slnx` at repo or solution root | Strong |
| `*.csproj` with `<TargetFramework>` / `<TargetFrameworks>` (`netX.Y`) | Strong |
| `global.json` with `sdk.version` (or roll-forward) | Medium |
| `Directory.Build.props` / `Directory.Packages.props` centralizing TFM or package versions | Medium |
| `nuget.config` alone | Weak (confirm .NET project exists) |

Do **not** treat a lone `package.json` or Python/`requirements.txt` as .NET.

## Version inputs (parametric — REQ-011 / RN07)

| Input | Rule |
|-------|------|
| `currentVersion` | Installed / declared TFM major (from `TargetFramework(s)` / SDK-reported major) |
| `targetVersion` | Desired major; **must** satisfy `target > current` |
| Semantics | Integer majors (`8`, `9`, `10`, …) mapped from TFM `net{N}.0` unless pack refs say otherwise |
| Skill id | Always `framework-upgrade` — **never** `dotnet10-upgrade` / `framework-upgrade-vN` |

Any in-range pair is valid when `target > current` (examples: `8→9`, `9→10`, `8→10` via hops). There is **no** hardcoded “only 8→10” lock. Future majors enter by extending `supported_range` + curated hop notes (or research) — not by renaming the skill.

## supported_range (inventory from curated refs)

Declared from **local** curated knowledge only (`skills/_shared/dotnet-guidelines/` + this pack’s parametric refs). Gaps → research protocol (skill `references/research-protocol.md` + `sources-catalog.md` official first); **do not invent local deltas**; extend this pack later without forking the skill.

**Inventory notes (this step):**

| Curated signal | Implication |
|----------------|-------------|
| Checklist / csharp-patterns prefer primary constructors, collection expressions, `required` | Modern C# era aligned with **.NET 8+** |
| `Microsoft.Extensions.Http.Resilience` / Polly v8 pointers | Ecosystem assumes **net8+**-class hosts |
| recommended-libraries: prefer org **LTS** TFM (no fixed major pin) | Practice gates are TFM-parametric; not a single-major skill |
| No local hop-delta corpus for majors **11 / 12 / 13** | Do **not** invent breaking-change deltas this step |

| Band | Majors | Local coverage basis |
|------|--------|----------------------|
| **In range (practice)** | **8, 9, 10** | `_shared/dotnet-guidelines/` practice gates apply; pack `plan-contract` / `compatibility` / `validation` describe parametric TFM/SDK path among these majors |
| **Partial / edge** | **6, 7** | May still appear in brownfield; guidelines partially apply; **no** dedicated hop-delta corpus in-pack |
| **Out of range** | **≤5** or **≥11** (until curated) | No local hop deltas / incomplete practice map → research + TE/STOP if inventing support |

When `currentVersion`→`targetVersion` path needs a major outside the in-range band, treat the **missing major** as out of range even if endpoints are listed.

## Cascade / hops

1. Prefer **sequential major hops** (`n → n+1`) for TFM/SDK unless official Microsoft upgrade guidance documents a supported multi-major path for that pair.
2. One hop at a time for `migrate`: plan → operator **sim** → apply → evidence → next hop.
3. Load pack refs progressively: this `PACK.md` → **one** file under `references/` → optional **one** `_shared/dotnet-guidelines/*.md`.
4. Official sources: skill `references/sources-catalog.md` + pack `references/knowledge-index.md`. `_shared/dotnet-guidelines/` = **post-upgrade quality gate** (audit/validate) — not a TFM hop substitute. RN08: Learn / .NET blog wins auxiliary.

## Progressive load index

| Need | Load |
|------|------|
| Detect / range / version inputs (this file) | `packs/dotnet/PACK.md` |
| Plan contract (parametric pairs) | `packs/dotnet/references/plan-contract.md` |
| TFM / SDK compatibility checks | `packs/dotnet/references/compatibility.md` |
| Validate / evidence gates for upgrade | `packs/dotnet/references/validation.md` |
| Shared guideline pointers | `packs/dotnet/references/knowledge-index.md` |
| Section routing | `packs/dotnet/references/index.md` |

## Skip D

Honor skill `references/skip-policy.md` — no external work-item mutation, OOS product brands, or duration/effort checkpoints in this pack.
