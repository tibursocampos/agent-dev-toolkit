# Sources catalog — framework-upgrade

Short catalog of **normative** vs **auxiliary** sources for packs and `_shared/*-guidelines`. **Pointers + when to load only** — never paste full articles, gists, or PEPs (`RNF-004` / `SR-NO-FULL-DUMP`).

Companion: `research-protocol.md` (out-of-range research), pack `knowledge-index.md` files (post-upgrade quality gates).

---

## RN08 — Official wins auxiliary

When an official framework/language source conflicts with a blog, gist, Medium post, or offline snapshot on a **breaking change or practice gate**, the **official source wins**. Auxiliary links are curated leads only — never SoT for migrate decisions or checklist Must gates.

---

## When to load

| Need | Load |
|------|------|
| Cite normative vs auxiliary URLs for a stack | This file (one stack section) |
| Out-of-range majors / research | `research-protocol.md` **after** official rows here |
| Post-upgrade practice audit | Pack `knowledge-index.md` → **one** `_shared/*-guidelines` file |
| Version deltas / hops | Pack refs — **not** this catalog (guidelines ≠ hop substitute) |

---

## .NET

### Normative (Must — official)

| Topic | URL | Aligns to |
|-------|-----|-----------|
| ASP.NET Core best practices | https://learn.microsoft.com/en-us/aspnet/core/fundamentals/best-practices?view=aspnetcore-10.0 (pt-BR: same path under `/pt-br/`) | DI lifetimes, `IHttpClientFactory`, avoid sync-over-async, logging |
| Memory / performance | https://learn.microsoft.com/en-us/aspnet/core/performance/memory?view=aspnetcore-10.0 | Pooling / allocation awareness |
| .NET 10 performance improvements (official blog) | https://devblogs.microsoft.com/dotnet/performance-improvements-in-net-10/ | Perf leads when targeting major 10 |

Local overlay: `skills/_shared/dotnet-guidelines/checklist.md`, `performance-aspnet.md`, `csharp-patterns.md`.

### Auxiliary (curated leads — not SoT)

| Topic | URL | Use |
|-------|-----|-----|
| Perf tips roundup | https://dev.to/unhacked/25-dicas-de-performance-com-net-10-368p | Optional audit leads; discard if conflicts with Learn |
| Reference guide (articles/videos) | https://renatogroffe.medium.com/net-10-guia-de-refer%C3%AAncia-artigos-dicas-v%C3%ADdeos-e-exemplos-de-utiliza%C3%A7%C3%A3o-0621fda1e498 | Discovery only |

### Gate bullets (existing guards only)

- Prefer DI lifetime correct for scope (e.g. scoped services not captive in singletons) — mirror repo DI / `csharp-patterns`
- `IHttpClientFactory` for `HttpClient` (checklist)
- No `.Result` / `.Wait()` / sync-over-async (checklist + patterns)
- Alloc/pooling / high-volume logging — only when coherent with Learn + local checklist

---

## Angular

### Normative (Must — official)

| Topic | URL | Aligns to |
|-------|-----|-----------|
| Angular Style Guide | https://angular.dev/style-guide | Naming, `inject()`, structure, class/style bindings |
| Best practices / Signals | https://angular.dev/best-practices · https://angular.dev/guide/signals | OnPush-adjacent, `computed` vs `effect` |

Local overlay: `skills/_shared/angular-guidelines/checklist.md`, `style-and-structure.md`, `signals-and-state.md`, `testing.md`.

### Auxiliary (curated leads — not SoT)

| Topic | URL | Use |
|-------|-----|-----|
| Angular practices gist | https://gist.github.com/Rubanrubi/c708b3b5725da983cbfd079796fb488d | Leads only; **official wins** |
| Maintenance Medium | https://medium.com/@ramajonnada/angular-21-project-maintenance-and-best-practices-9b4d1fefe34d | Discovery; maj ≥20 still out of pack range until curated |

### Gate bullets (existing guards only)

- Style / structure + `[class]`/`[style]` (checklist / style-and-structure)
- Signals + `computed` over misuse of `effect` (signals-and-state)
- OnPush presentational when neighbors use it (standalone-and-templates)
- Testing: `ng test` / harnesses (testing.md)

---

## Python

### Normative (Must — official)

| Topic | URL | Aligns to |
|-------|-----|-----------|
| PEP 8 | https://peps.python.org/pep-0008/ | Naming, imports, layout |

Local overlay: `skills/_shared/python-guidelines/checklist.md`, `google-style.md`, `principles.md`. Pack `python` remains **Could** (REGISTRY slot).

### Auxiliary (curated leads — not SoT)

| Topic | URL | Use |
|-------|-----|-----|
| IST best-practices gist | https://gist.github.com/ruimaranhao/4e18cbe3dad6f68040c32ed6709090a3 | Leads only; do not paste body |
| Real Python best practices | https://realpython.com/tutorials/best-practices/ | Discovery |

### Gate bullets (existing guards only)

- Naming / imports / docstrings — `google-style.md` + PEP 8 pointer
- Principles / trust boundaries — `principles.md`

---

## Progressive load reminder

Catalog row → optional **one** local guideline file → never full article/gist/PEP paste. Pack version-deltas stay in pack refs; `_shared/*-guidelines` are **post-upgrade quality gates** (audit/validate), not hop substitutes.
