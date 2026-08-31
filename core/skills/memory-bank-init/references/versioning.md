## Versioning note (for guides)

**Commit bank when product knowledge; never commit secrets.** Do **not** treat `/memory-bank/` as a required SDD gitignore entry.

| `storage_mode` | Action |
|----------------|--------|
| **repository** | Ensure SDD `.gitignore` block per `STORAGE.md` (`/features/` + safety-net only) before first write — **do not** add `/memory-bank/` |
| **global** | Bank under `<classic.path>/memory-bank/` - **do not** edit consumer `.gitignore` |
