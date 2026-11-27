# 10 — ADT Delivery Flow

ADT Delivery is a separate end-to-end path for carrying one demand through refinement, planning, implementation, and review in one evolving `features/NNN-slug/PLAN.md`. It does not use the Classic SDD or Orchestrated Delivery artifact trees or gates. The source contract is [`adt-delivery-flow/SKILL.md`](../../core/skills/adt-delivery-flow/SKILL.md) and its linked lifecycle references.

## Stages

| Stage | Skill | Result |
|-------|-------|--------|
| Refine | `adt-delivery-refine` | Clarified outcome, scope, evidence, material decisions, and specialist triage recorded in the feature PLAN. |
| Plan | `adt-delivery-plan` | Complete executable plan in the same file and one explicit approval before implementation. |
| Implement | `adt-delivery-implement` | Approved steps implemented, required validation completed, and the existing `adt-code-review` performed; evidence and progress remain in the plan. |

Use `adt-delivery-flow` for end-to-end work or to resume this flow. Stage skills can be invoked directly when the operator requests one stage. The stages still run in order: refinement and planning are not skipped. If the request is analysis-only, the flow stops after refinement and reports findings without asking for plan approval.

## Approval and questions

The plan can be drafted and refined before approval. One explicit approval covers the completed plan before implementation. If a later change materially affects behavior, acceptance, scope, access, or an implementation decision, resolve that decision for the affected work and update the plan before continuing. Only unresolved material questions block dependent work; unrelated work can continue.

## Storage and context

The working plan lives at `features/NNN-slug/PLAN.md`, with the feature directory selected according to the ADT storage rules. Its internal operational record carries the stage ledger and approval evidence. Do not copy the plan into Classic `USnn/PRD/` and `USnn/PLAN/` folders or O1/O2/O3 progress artifacts. Existing Memory Bank, CHANGE, CONTINUITY, or TASKS content may be used when relevant but is not a general prerequisite.

## Implementation closeout

Follow validation and review required by the approved plan and the ADT implementation skill. Reuse current evidence when it still covers the same unchanged scope; rerun checks only when a change invalidates them. This guide does not add a test-per-step or universal security-review rule. The flow never commits, pushes, merges, or publishes automatically.
