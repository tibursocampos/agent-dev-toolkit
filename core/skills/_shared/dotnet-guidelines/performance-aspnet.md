# ASP.NET Core performance and fundamentals (pointers)

Progressive load: cite URLs and align to existing checklist / `csharp-patterns` gates. **Do not** paste Learn articles or blog posts wholesale (`RNF-004`).

**RN08:** Official Microsoft Learn / .NET blog wins auxiliary blogs and gists when they conflict.

---

## Normative sources

| Topic | URL |
|-------|-----|
| ASP.NET Core best practices | https://learn.microsoft.com/en-us/aspnet/core/fundamentals/best-practices?view=aspnetcore-10.0 |
| Same (pt-BR) | https://learn.microsoft.com/pt-br/aspnet/core/fundamentals/best-practices?view=aspnetcore-10.0 |
| Memory / performance | https://learn.microsoft.com/en-us/aspnet/core/performance/memory?view=aspnetcore-10.0 |
| .NET 10 performance improvements (official blog) | https://devblogs.microsoft.com/dotnet/performance-improvements-in-net-10/ |

---

## Gates aligned to toolkit guards

Load only when the task touches hosting / HTTP / DI / hot paths:

| Gate | Local home |
|------|------------|
| Correct DI lifetimes (no captive scoped in singleton) | Mirror repo DI; `csharp-patterns.md` |
| `IHttpClientFactory` for `HttpClient` | `checklist.md` · `recommended-libraries.md` |
| Avoid sync-over-async (`.Result` / `.Wait()`) | `checklist.md` · `csharp-patterns.md` |
| Allocation / pooling awareness on hot paths | This file + Learn memory page (pointer only) |
| High-volume logging discipline | Learn best practices (pointer) — match project logger patterns |

---

## Auxiliary (leads only — not SoT)

- https://dev.to/unhacked/25-dicas-de-performance-com-net-10-368p
- https://renatogroffe.medium.com/net-10-guia-de-refer%C3%AAncia-artigos-dicas-v%C3%ADdeos-e-exemplos-de-utiliza%C3%A7%C3%A3o-0621fda1e498

Discard any tip that conflicts with Learn / checklist Must items.

---

## Cross-refs

- Delivery checklist: `checklist.md`
- Framework-upgrade catalog: `skills/framework-upgrade/references/sources-catalog.md`
- Pack quality gate index: `skills/framework-upgrade/packs/dotnet/references/knowledge-index.md`
