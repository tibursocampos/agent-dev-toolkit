## Versioning note (for guides)

**Commit bank when product knowledge; never commit secrets.** Do **not** treat `/memory-bank/` as a required SDD gitignore entry.

| `storage_mode` | Action |
|----------------|--------|
| **repository** | Ensure SDD `.gitignore` block per `STORAGE.md` and `features_versioned` before first write — **do not** add `/memory-bank/`; always `!/docs/documentation-plan/plan.md` |
| **global** | Bank under `<classic.path>/memory-bank/` - **do not** edit consumer `.gitignore` |

| `features_versioned` | `/features/` `/docs/features/` in `.gitignore` |
|---------------------|-----------------------------------------------|
| `false` (default) | Yes |
| `true` | No — version features in git |
