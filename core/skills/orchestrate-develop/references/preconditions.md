## Preconditions checklist

- [ ] Gate check reported; user **sim** for this O3 run / next spawn
- [ ] Feature and/or PLAN path resolved (`STORAGE.md`, classic)
- [ ] **Step 0** Memory Bank Gate done (`auto`; explicit `skip-memory-bank` only to bypass)
- [ ] At least one `features/**/PLAN/PLAN_*.md` under story folders (or global `.../features/**/PLAN/`)
- [ ] Next step deps **Completed** / **Concluídos**
- [ ] Parent will **not** implement app code
- [ ] Child prompts include `memoryBankPath` (read-only, selective)

If no PLAN -> hand off to O2 / `sdd-plan`. If user prefers no orchestrator -> document manual `sdd-develop` and stop (Classic SDD: no memory-bank gate - CA7).

---

## Step 0 - Memory Bank Gate (CA4 / CT3)

| Check | Pass |
|-------|------|
| Bank path | Resolved `bank_root` (`STORAGE.md`) - not under `features/` |
| Fresh healthy bank | No rewrite; CONTINUITY status `fresh` |
| Refresh this run | CONTINUITY status `refreshed` |
| Children | Receive bank path; selective read; no bank dump |
| CONTINUITY vs bank | CONTINUITY = phase/handoff; bank = workspace map |
| 1-step contract | Unchanged - one child = one PLAN step |

## Step N - refresh-light (after code changes)

| Check | Pass |
|-------|------|
| Trigger | At least one child changed app files this O3 run |
| Mode | `memory-bank-init` **`refresh-light`** only (not full prose rewrite) |
| Confirm | pt-BR `sim` / `pular` / `cancelar` before write |
| Skip | No code changes, or user chose `pular` |
| CONTINUITY | Status `refreshed` when Step N ran |
