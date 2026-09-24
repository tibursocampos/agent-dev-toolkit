## Optional flows (user-driven)

| After last step | User may run |
|-----------------|--------------|
| Review diff | `/code-review` |
| Commit | `/commit` (skill asks memory-bank + docs **sim/pular** when those trees exist — do not skip the ask) |
| Open PR | GitHub web UI with repo template - no external work-item fields |

Do not auto-create PRs or link external trackers.

## When all PLAN steps are done (parent must ask)

Present **both** options; wait for the user (do not assume):

```text
US/PLAN concluído. Próximo?
1) /code-review (single ou multi-ângulo)
2) /commit
```

### Before `/commit` (Classic SDD)

If the user chooses commit (or asks `/commit` right after the last step), **ask and wait** for each applicable item (**sim** / **pular**). Do **not** run bank/docs writes on silence.

| When present | Ask (pt-BR) | On **sim** |
|--------------|-------------|------------|
| `memory-bank/` (or bank_root from `STORAGE.md`) | `Posso atualizar o memory-bank (refresh-light) em '{bank_root}'? (sim / pular)` | `/memory-bank-init` mode `refresh-light` |
| Project docs (`docs/documentation-plan/plan.md` and/or `docs/overview.md` / `docs/domains/`) | `Posso atualizar a documentação do projeto? (sim / pular)` | Pending plan steps → `/document-implement`; no plan but docs exist → `/document-plan` then implement; greenfield docs → `/document-plan` |

Only then hand off to `/commit` (the commit skill repeats the same asks if still pending — idempotent skip when user already answered **pular** this turn).

### After `/code-review` with Changes required

Recommended loop (not mandatory) — ask each (**sim** / **pular**); see `code-review` Handoff.

---
