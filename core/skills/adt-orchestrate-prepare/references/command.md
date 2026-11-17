# adt-orchestrate-prepare — command playbook

Load one section per current task. O2 owns the only contextual progress table; internal skills do not render another.

| Step | Action | Reference |
|---|---|---|
| 1 | Resolve feature path and current FEATURE/STORY context | `STORAGE.md`, `references/preconditions.md` |
| 2 | Identify material questions, dependencies, and eligible stories | `references/preconditions.md` |
| 3 | Choose sequential or parallel document preparation when useful | `references/mode-selection.md`, `SPAWN.md` only if delegating |
| 4 | Prepare/review PRD with `adt-sdd-spec` | `references/per-story-contracts.md`, `adt-sdd-spec/SKILL.md` |
| 5 | Prepare/review PLAN with `adt-sdd-plan`; checklist remains optional | `references/per-story-contracts.md`, `adt-sdd-plan/SKILL.md` |
| 6 | Review complete PLAN set and request one explicit approval | `references/approval-gates.md` |
| 7 | Reconcile and hand off only approved PLAN paths | `references/continuity-handoff.md` |

Render the complete O2 table at start, meaningful transitions, blocking decisions/responses, specialist reconciliation, resume, and close/handoff according to `LIVE-STAGE-TABLE.md`. Do not add an accumulating checkpoint table. O2 does not write application code.
