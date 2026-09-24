# Review N+1 / hot-path refs (WS16a / REQ-016)

**Family:** `N+1`. Load during Process §4 (and multi-angle **qualidade**) whenever the diff touches data access, HTTP fan-out, loops over I/O, or UI list→detail fetches.

**Language:** English identifiers and checklist labels. Report prose follows session language.

**Contract:** actionable smells + short pointers — do not paste guideline packs into the report.

Companions: `references/verification.md` (Performance row), `references/dotnet-checklist.md` (EF / data), `references/report-template.md` § Performance, `{{TOOLKIT_ROOT}}/skills/_shared/dotnet-guidelines/checklist.md`, optional handoff `/performance-profile`.

---

## What counts as N+1 (review bar)

| Pattern | Smell in the diff |
|---------|-------------------|
| ORM / EF | Loop / projection that triggers a query per item; missing `Include` / split query / batched load; tracking where read-only `AsNoTracking` fits |
| Repository / service | `GetById` (or equivalent) inside `foreach` / `Select` over a collection |
| HTTP / gRPC | Per-item outbound call in a list handler without batch/bulk API |
| Messaging | Per-message sync fan-out that could be batched when neighbors already batch |
| Frontend | List render that fires one request per row (waterfall) without existing cache/batch pattern |

Only flag **changed** paths or newly introduced call sites. Do not demand a full perf audit unless PRD/PLAN requires it.

---

## Actionable checklist (N+1 family)

- [ ] No new per-item DB/HTTP call inside collection loops on hot paths
- [ ] EF/read models: no obvious N+1; read-only queries consider `AsNoTracking` when appropriate
- [ ] Unbounded work: no unbounded `ToList` / full-table scan introduced without filter/pagination when neighbors paginate
- [ ] Async: I/O-bound new work uses async (no unjustified `.Result` / `.Wait()` on those paths)
- [ ] Frontend/API: list→detail fetch patterns do not introduce row-wise requests without justification
- [ ] If smell is suspected but unproven: note as **important** with `path:line` and what to measure — do not invent timings

**Severity hint:** clear per-item query/call on a list endpoint → **important** (or **critical** if PRD cites scale/SLA); style-only async → lower.

## Pointer index (open on demand)

| Topic | Path |
|-------|------|
| .NET condensed EF row | `references/dotnet-checklist.md` |
| Focus areas table | `references/verification.md` |
| Report § Performance | `references/report-template.md` |
| Broader .NET quality bar | `{{TOOLKIT_ROOT}}/skills/_shared/dotnet-guidelines/checklist.md` |
| Deep profiling (handoff) | `/performance-profile` — only when user asks or PRD requires |

## CT6 marker (N+1)

- [ ] This file is reachable from `code-review` Reference routing / Process §4
- [ ] Checklist is actionable without dumping performance guideline bodies
