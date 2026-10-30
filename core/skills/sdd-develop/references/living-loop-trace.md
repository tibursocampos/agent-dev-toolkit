## Living loop + TRACE

Canonical path: `features/NNN-slug/TRACE.jsonl`.

| Phase | Event | Action |
|-------|-------|--------|
| converge | `converge` | Decide which CHANGE/PRD deltas become current |
| sync current | `sync_current` | Selective write to `memory-bank/` / named `docs/` (`targets[]`) |
| archive | `archive` | Close wave; `status` = `archived` |

```powershell
pwsh -NoProfile -File "{{TOOLKIT_ROOT}}/scripts/validation/validate-trace.ps1" -FeatureRoot features/NNN-slug [-RequireArchiveComplete]
```

Template: `skills/_shared/templates/features/TRACE.jsonl`. Contract: `TRACE-ARCHIVE-CONTRACT.md`.

Mid-feature: optional trail events; TRACE may be absent until close. At archive: require living-loop triad + coherent sync targets (no `openspec/` / `.specs/` / SQLite SoT).

---

## Procedure

1. Append events to `features/NNN-slug/TRACE.jsonl` (template: `templates/features/TRACE.jsonl`; contract: `TRACE-ARCHIVE-CONTRACT.md`).
2. Run **converge → sync current → archive**: selective updates to living docs (`memory-bank/` / named `docs/`); do **not** dump full bank/PRD (`SR-NO-FULL-DUMP`).
3. Ensure TRACE includes ordered living-loop events `converge`, `sync_current`, `archive`.
4. Run the structural gate above with `-RequireArchiveComplete` (deterministic — never LLM-as-validator). Exit ≠ 0 → **STOP**; do not declare archive done.

**Verifier ≠ O3:** archive/TRACE validation is sequential in this session — do not use Agent/O3 parallelism as the archive gate.
