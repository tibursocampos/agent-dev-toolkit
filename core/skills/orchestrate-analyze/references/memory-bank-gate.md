## Step 0 - Memory Bank Gate (CT2 / CA3)

Run **before** triage (SKILL §3). Contract: `MEMORY-BANK.md`. Skill: `memory-bank-init`.

| Check | Pass criteria |
|-------|---------------|
| Bank path | Resolved `bank_root` via `STORAGE.md` (`$Cwd/memory-bank/` or `<classic.path>/memory-bank/`) - **not** under `features/NNN-slug/` |
| Policy | `auto` default; `skip` only with explicit user flag |
| Healthy | Selective read; no write; CONTINUITY status `fresh` |
| Missing/stale | Confirm -> create/refresh; status `created` / `refreshed` |
| Gitignore | Repository: SDD block per `STORAGE.md` (**not** `/memory-bank/`; commit bank when product knowledge; never commit secrets); global: do not edit `.gitignore` |
| CONTINUITY | Path + status only - no bank body dump |
| Parent context | Lean - do not load entire bank |

**CA6:** memory-bank = repo map; CONTINUITY = feature handoff. Parallel scopes.
