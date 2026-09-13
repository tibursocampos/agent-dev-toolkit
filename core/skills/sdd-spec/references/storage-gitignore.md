## Storage and `.gitignore` (spec skill)

Before `Write` in **repository** mode, follow `STORAGE.md` § Repository mode - `.gitignore`: read `features_versioned` from manifest and apply the matching SDD block. When `false`, include `/features/` and `/docs/features/`; when `true`, omit them. Always include safety-net `/PRD/`, `/PLAN/`, `/docs/PRD/`, `/docs/PLAN/` and `/docs/documentation-plan/*` with `!/docs/documentation-plan/plan.md`. **Do not** add `/memory-bank/` — commit bank when product knowledge; never commit secrets. Run on first SDD write in a repo.

**Global** mode: no `.gitignore` changes (do not add features / memory-bank / PRD / PLAN patterns).

After choosing storage, write `{{SDD_ROOT}}/<repo-id>/manifest.json` with `artifact_language` and `features_versioned` when persisting; when `artifact_language` unset, match user chat per `LANGUAGE.md`.
