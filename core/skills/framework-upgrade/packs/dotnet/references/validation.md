# Dotnet pack — validation

## When

Use in mode `validate`, or after each approved `migrate` hop, before claiming the hop done.

## Gates (cheap → stricter)

| Gate | Pass criteria |
|------|----------------|
| TFM / SDK | Projects and `global.json` (if present) reflect the hop’s target major |
| Restore / build | Solution restores and builds for touched projects |
| Tests | Targeted test projects for changed surfaces pass (repo convention) |
| Practice checklist | Selective load of **one** `_shared/dotnet-guidelines` file via `knowledge-index.md` — post-upgrade quality gate, not hop substitute; no full-tree dump |
| Official sources | Prefer Learn / catalog (`sources-catalog.md`); RN08 official wins auxiliary |
| Skip D | No OOS brand / work-item mutation introduced by the hop |

## Evidence (minimal)

Record in the session / decision register:

- Pack id + `PACK.md` path
- `currentVersion` → `targetVersion` (and hop if multi-major)
- Commands run + exit outcomes (restore/build/test)
- Gaps deferred to research (if any)

Do not mark migrate complete on silence; operator **sim** remains required before mutating hops (skill RN02 / TE05).
