## Living loop + TRACE (REQ-006 / CA5)

Canonical path: `features/NNN-slug/TRACE.jsonl`.

| Phase | Event | Action |
|-------|-------|--------|
| converge | `converge` | Decide which CHANGE/PRD deltas become current |
| sync current | `sync_current` | Selective write to `memory-bank/` / named `docs/` (`targets[]`) |
| archive | `archive` | Close wave; `status` = `archived` |

```powershell
.\scripts\validation\validate-trace.ps1 -FeatureRoot features/NNN-slug [-RequireArchiveComplete]
```

Template: `skills/_shared/templates/features/TRACE.jsonl`. Contract: `TRACE-ARCHIVE-CONTRACT.md`. Smoke: `Assert-TraceArchiveContract.ps1`.

Mid-feature: optional trail events; TRACE may be absent until close. At archive: require living-loop triad + coherent sync targets (no `openspec/` / `.specs/` / SQLite SoT).

---
