# ADT delivery - PLAN.md template

## Authoring rules

- One evolving `PLAN.md`; each decision or criterion lives in one place and steps reference it by id. Refinement becomes plan input, not a copied artifact. Omit inapplicable fields; never invent scope.
- Optional US groupings (also two US) use the same plan and approval; no extra story files.
- Body language follows the artifact content language resolved by `{{TOOLKIT_ROOT}}/skills/_shared/agents/LANGUAGE.md`; section headings below stay in English; identifiers and paths stay English.
- Do not mandate a test after every step; choose checks by risk.
- Status tokens in Progress are exactly: `PENDING`, `IN_PROGRESS`, `COMPLETED`, `BLOCKED`, `SKIPPED`.
- The chat progress table is NEVER written into PLAN.md; only the Progress ledger below is persisted (the chat table standard is `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/LIVE-STAGE-TABLE.md`).

## Template

```markdown
## Normative content

- Goal and user request: [observable outcome, scope and exclusions]
- Evidence: [current behavior, verified facts and sources; label inferences and suggestions separately]
- Decisions and questions: [decisions, assumptions, unresolved questions, dependencies, risks] plus the specialist triage table defined in `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/TRIAGE.md` (Flag | Value | Basis | Result)
- Acceptance: [observable, measurable criteria; happy path, failure and edge cases where applicable; ids A1, A2, ...]
- Optional US: [group related criteria and steps only when useful]
- Impact: [affected files or bounded path patterns; contracts, data migration, integrations, error handling when applicable]
- Steps: [ordered S1, S2, ... outcomes with dependencies and safe parallelism; reference acceptance and decision ids]
- Validation: [checks by risk; final validation; final `code-review` handoff]

## Operational record

- Mode: full|analysis
- Subagents: native|none
- Model choice: inherit|reuse_saved|choose_model|n/a
- Stage ledger: refine=pending|done, plan=pending|approved, implement=pending|in_progress|done
- Approval: [format defined in `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/PLAN-LIFECYCLE.md`]
- Choices: [branch, cadence, review mode, base and focus as applicable]
- Progress: [per step PENDING | IN_PROGRESS | COMPLETED | BLOCKED | SKIPPED; evidence, actual results, blockers, next action]
- Closeout: [final validation and the adjacent review report `CODE-REVIEW.md` pending until performed; results and limitations]
```

## Completed step and interruption

- A completed step records outcome and evidence only; it does not imply final validation or delivery is complete.
- On interruption record partial work, evidence, blockers and next action; on resume reconcile with the real working tree and plan.

## Planner self-check before asking approval

- Check: scope and acceptance coverage; evidence versus assumptions; contradictions; unresolved material questions; whether steps and validation can run against the listed paths. Resolve material gaps with the operator first. This is a targeted self-check, not a separate reviewer, cold review or review loop.
