## Optional flows (user-driven)

| After last step | User may run |
|-----------------|--------------|
| Review diff | `/code-review` |
| Commit | `/commit` (skill asks memory-bank + docs **sim/pular** when those trees exist — do not skip the ask) |
| Open PR | GitHub web UI with repo template - no external work-item fields |

Do not auto-create PRs or link external trackers.

## When all PLAN steps are done (parent must ask)

Present **both** options; wait for the user (do not assume). That question has no written deadline: follow `core/policy/guardrails.md` § Open questions without a written deadline. Use the host interactive question when the host offers one; otherwise ask in text. Send no further message until the operator answers. Silence, timeout, and end of turn are not answers. After the answer, resume the chosen function or declare a blocker with the cause.

```text
US/PLAN concluído. Próximo?
1) /code-review (single ou multi-ângulo)
2) /commit
```

### Before `/commit` (Classic SDD)

If the user chooses commit (or asks `/commit` right after the last step), **ask and wait** for each applicable item (**sim** / **pular**). Those asks have no written deadline: follow `core/policy/guardrails.md` § Open questions without a written deadline. Use the host interactive question when the host offers one; otherwise ask in text. Send no further message until the operator answers every pending question. Silence, timeout, and end of turn are not answers. Do **not** run bank/docs writes on silence. After the answer, or after an intermediate skill the operator already authorized, resume the original skill until the requested function finishes or that skill declares a blocker with the cause. Keep the asks below.

| When present | Ask (pt-BR) | On **sim** |
|--------------|-------------|------------|
| `memory-bank/` (or bank_root from `STORAGE.md`) | `Posso atualizar o memory-bank (refresh-light) em '{bank_root}'? (sim / pular)` | `/memory-bank-init` mode `refresh-light` |
| Project docs (`docs/documentation-plan/plan.md` and/or `docs/overview.md` / `docs/domains/`) | `Posso atualizar a documentação do projeto? (sim / pular)` | Pending plan steps → `/document-implement`; no plan but docs exist → `/document-plan` then implement; greenfield docs → `/document-plan` |

Only then hand off to `/commit` (the commit skill repeats the same asks if still pending — idempotent skip when user already answered **pular** this turn).

### After `/code-review` with Changes required

Recommended loop (not mandatory) — ask each (**sim** / **pular**); see `code-review` Handoff.

---
