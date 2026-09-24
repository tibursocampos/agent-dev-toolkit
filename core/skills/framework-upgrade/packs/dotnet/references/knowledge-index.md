# Dotnet pack — knowledge index (pointers only)

Progressive load: cite the path and load **one** guideline file when needed. Do **not** paste guideline bodies into the upgrade session (`RNF-004` / `SR-NO-FULL-DUMP`).

## Role vs version deltas

`_shared/dotnet-guidelines/` are a **post-upgrade quality gate** for modes `audit` / `validate` (and selective migrate checks). They do **not** substitute pack hop / TFM version-deltas. Official Microsoft Learn / .NET blog wins auxiliary blogs/gists (**RN08** — see skill `references/sources-catalog.md`).

## Shared .NET guidelines

Portable root: `skills/_shared/dotnet-guidelines/` (InstallRoot after sync).

| Topic | Portable path | Notes |
|-------|---------------|-------|
| Delivery checklist | `skills/_shared/dotnet-guidelines/checklist.md` | PR / build / DI / HttpClient / sync-over-async; Must Learn URLs |
| ASP.NET perf / fundamentals | `skills/_shared/dotnet-guidelines/performance-aspnet.md` | Learn best practices + memory + .NET 10 perf blog pointers |
| C# patterns | `skills/_shared/dotnet-guidelines/csharp-patterns.md` | Constants, signatures, modern C# preferences |
| C# formatting | `skills/_shared/dotnet-guidelines/csharp-formatting.md` | CSharpier / analyzer vs `dotnet format` whitespace |
| Clean architecture | `skills/_shared/dotnet-guidelines/clean-architecture.md` | Layer dependency rules |
| Vertical slice | `skills/_shared/dotnet-guidelines/vertical-slice.md` | Feature-folder alternative |
| DDD tactical | `skills/_shared/dotnet-guidelines/ddd-tactical.md` | Aggregates / value objects when in scope |
| Event-driven | `skills/_shared/dotnet-guidelines/event-driven.md` | Messaging patterns when in scope |
| Project references | `skills/_shared/dotnet-guidelines/project-references.md` | Project graph hygiene |
| NuGet configuration | `skills/_shared/dotnet-guidelines/nuget-configuration.md` | feeds / central package mgmt |
| Recommended libraries | `skills/_shared/dotnet-guidelines/recommended-libraries.md` | LTS TFM preference; Http resilience |
| String manipulation | `skills/_shared/dotnet-guidelines/string-manipulation.md` | Allocation-aware string use |

## Official sources (pointers)

| Kind | URL |
|------|-----|
| Normative | https://learn.microsoft.com/en-us/aspnet/core/fundamentals/best-practices?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/performance/memory?view=aspnetcore-10.0 · https://devblogs.microsoft.com/dotnet/performance-improvements-in-net-10/ |
| Catalog | `skills/framework-upgrade/references/sources-catalog.md` |

## Inventory → supported_range

| Guideline signal | Major implication |
|------------------|-------------------|
| Primary constructors / collection expressions / `required` | Practice aligned with **.NET 8+** |
| Polly v8 / `Microsoft.Extensions.Http.Resilience` | Modern host stack (**net8+**-class) |
| Prefer org LTS TFM (no pin in skill id) | Parametric majors; not `dotnet10-*` |
| No curated hop notes for 11+ | **≥11** out of range until pack extension |

Declared pack band: see `../PACK.md` § `supported_range`. Majors outside that band → skill `references/research-protocol.md`.
