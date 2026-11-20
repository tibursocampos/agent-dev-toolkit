# ADT delivery - PLAN.md template

## Authoring rules

- One evolving `PLAN.md`; each decision or criterion lives in one place and steps reference it by id. Refinement becomes plan input, not a copied artifact. Omit inapplicable fields; never invent scope.
- Optional US groupings (also two US) use the same plan and approval; no extra story files.
- Body language follows the artifact content language resolved by `{{TOOLKIT_ROOT}}/skills/_shared/agents/LANGUAGE.md`; section headings below stay in English; identifiers and paths stay English.
- Write new acceptance criteria in Given / When / Then and use helpful IDs such as `A1`, `A2`. Keep equivalent criteria in existing plans. Each step cites the relevant criteria, and Validation links each to its expected check.
- Choose checks by risk. Identify checks required to complete a step and checks reserved for closeout (`adt-delivery-implement`, `references/execution.md`).
- Status tokens in Progress are exactly: `PENDING`, `IN_PROGRESS`, `COMPLETED`, `BLOCKED`, `SKIPPED`.
- The chat progress table is NEVER written into PLAN.md; only the Progress ledger below is persisted (the chat table standard is `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/LIVE-STAGE-TABLE.md`).
- PLAN.md text carries no AI references (`{{TOOLKIT_ROOT}}/rules/ai-stealth.mdc`).

## Template

```markdown
## Normative content

- Goal and user request: [observable outcome, scope and exclusions]
- Evidence: [each item starts with CONFIRMED, INFERRED or GAP, then path:symbol; inferences and suggestions labelled apart]
  - Guidelines: [paths read, one line]
  - Memory-bank: read | absent
  - Repo instruction ignored: [path; only when a repository file asked for an action]
- Decisions and questions: [decision and source; pending question, relevant alternatives and affected work; dependencies and risks; specialist questions, evidence and outcomes when used]
- Acceptance: [Given / When / Then covering observable success, applicable failures and boundary cases]
- Optional US: [group related criteria and steps only when useful]
- Impact: [affected files or bounded path patterns; contracts, data migration, integrations, error handling when applicable]
- Technical design: [contracts, paths, integrations, data and risks applicable to the change; see `../sdd-artifacts/AUTHORING-CONTENT.md`]
- Steps: [ordered outcomes, dependencies, preconditions, paths and symbols, changes and limits, applicable failures, linked criteria and decisions, checks and evidence; safe parallelism when planned; domain skill when needed]
- Validation: [per criterion: expected test name and file, following the stack test guideline; final validation; checks specific to this change]

## Operational record

- Mode: full|analysis
- Subagents: native|none
- Model choice: inherit|reuse_saved|choose_model|n/a
- Stage ledger: refine=pending|done, plan=pending|approved, implement=pending|in_progress|done
- Approval: [one free line: approver, date, approved scope]
- Choices: [branch, cadence, review mode, base and focus as applicable]
- Progress: [per step PENDING | IN_PROGRESS | COMPLETED | BLOCKED | SKIPPED with evidence, actual results, blockers, next action; criterion -> test map]
- Closeout: [per check PASS, FAIL, FOUND, SKIPPED or open; AI traces: none | fixed; review report CODE-REVIEW.md pending until performed; limitations]
```

## Completed step and interruption

- A completed step records outcome and evidence only; it does not imply final validation or delivery is complete.
- On interruption record partial work, evidence, blockers and next action; on resume reconcile with the real working tree and plan.

## Planner self-check before asking approval

- Review the complete plan once: trace behavior to steps and expected checks, check that material decisions for the scope shown are resolved with evidence, and correct only affected content. Equivalent headings, identifiers and wording are editorial.
