## Closeout after the requested implementation scope

When the requested scope completes, run the validation required by the PLAN and perform one substantive `adt-code-review`. Reuse a current result when it covers the same stack, command, and unchanged working tree; do not repeat a full suite for ceremony. If the review causes an in-scope correction, rerun only affected checks and recheck the correction. Record results and limits in the PLAN evidence. For `step_by_step`, do not close the whole plan after an intermediate step; stop at the cadence boundary. See `_shared/sdd-artifacts/PIPELINE.md` § Closeout.

## Optional handoffs (user-driven)

| After last step | User may run |
|-----------------|--------------|
| Commit | `/adt-commit` (skill asks memory-bank + docs **sim/pular** when those trees exist — do not skip the ask) |
| Open PR | GitHub web UI with repo template - no external work-item fields |

Do not auto-create PRs or link external trackers.

## After all requested PLAN scope is done

Report completion and its evidence. Commit and PR remain optional handoffs and require the user's request.

Example handoff in pt-BR:

```text
US/PLAN concluído. Posso ajudar com uma revisão ou preparar o commit se você solicitar.
```

### Before `/adt-commit` (Classic SDD)

If the user chooses commit (or asks `/adt-commit` right after the last step), **ask and wait** for each applicable item (ids `confirm` / `skip`, rendered in the user's language per `core/skills/_shared/agents/QUESTIONS.md`). Those asks have no written deadline: follow `core/policy/guardrails.md` § Open questions without a written deadline. Use the host interactive question when the host offers one; otherwise ask in text. Send no further message until the operator answers every pending question. Silence, timeout, and end of turn are not answers. Do **not** run bank/docs writes on silence. After the answer, or after an intermediate skill the operator already authorized, resume the original skill until the requested function finishes or that skill declares a blocker with the cause. Keep the asks below.

| When present | Ask (ids `confirm` / `skip`) | On `confirm` |
|--------------|-------------|------------|
| `memory-bank/` (or bank_root from `STORAGE.md`) | Render in the user's language. pt-BR example: `Posso atualizar o memory-bank (refresh-light) em '{bank_root}'? (sim / pular)` | `/adt-memory-bank` mode `refresh-light` |
| Project docs (`docs/documentation-plan/plan.md` and/or `docs/overview.md` / `docs/domains/`) | Render in the user's language. pt-BR example: `Posso atualizar a documentação do projeto? (sim / pular)` | Pending plan steps → `/adt-document-implement`; no plan but docs exist → `/adt-document-plan` then implement; greenfield docs → `/adt-document-plan` |

Only then hand off to `/adt-commit` (the commit skill repeats the same asks if still pending — idempotent skip when user already answered **pular** this turn).

### After `/adt-code-review` with Changes required

Recommended loop (not mandatory) — ask each (**sim** / **pular**); see `adt-code-review` Handoff.

---
