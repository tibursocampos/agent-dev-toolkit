## Storage and `.gitignore` (spec skill)

Before `Write` in **repository** mode, follow `STORAGE.md` § Repository mode - `.gitignore`: ensure SDD block includes **`/features/`**. Keep `/PRD/`, `/PLAN/`, `/docs/PRD/`, `/docs/PLAN/` in `.gitignore` **only as a safety net** (not active Classic SDD paths). **Do not** add `/memory-bank/` — commit bank when product knowledge; never commit secrets. Run this on first SDD write in a repo.

**Global** mode: no `.gitignore` changes (do not add features / memory-bank / PRD / PLAN patterns).

After choosing storage, write `{{SDD_ROOT}}/<repo-id>/manifest.json` with `artifact_language` when persisting an explicit override (`pt-BR`, `en`, …); when unset, match user chat per `LANGUAGE.md`.
