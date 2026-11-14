---
name: adt-delivery-flow
description: Coordinate an ADT delivery from demand through refinement, one approved plan, implementation and review. Use when invoking adt-delivery-flow (host examples /adt-delivery-flow, $adt-delivery-flow, use skill adt-delivery-flow).
---

## STOP - Read before ANY tool call

Read `_shared/skill-boilerplate.md` first. It holds the guardrails read, the session gate rule, the user `sim` rule, the one-step rule, the gate check, and the user chat language rule. The steps below are skill-specific only.

ADT exceptions to the Classic gates: this flow keeps one evolving `features/NNN-slug/PLAN.md`, one explicit plan approval (`{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/PLAN-LIFECYCLE.md`) instead of per-step `step_confirmed`, and its own cadence. The draft `PLAN.md` may be created and refined before approval. Everything else in the boilerplate still applies.

**Step 0 is blocking.** Run Step 0 before any step: complete `{{TOOLKIT_ROOT}}/skills/adt-delivery-flow/references/step0.md`. A failed preflight or an unanswered model question stops the run.

# Skill: adt-delivery-flow

## Trigger

Invoke `adt-delivery-flow` (host forms: `/adt-delivery-flow`, `$adt-delivery-flow`, `use skill adt-delivery-flow`).

**Negative signal:** applies as defined in `_shared/skill-boilerplate.md`; the skill-specific signals are listed below.

- Invoke when the operator asks to deliver a demand end to end with the ADT delivery flow, or to resume a feature of this flow.
- Invoke also for an analysis-only request (for example "analysis only" or "so analise"); see Analysis-only mode.
- Separate from Classic SDD and O1/O2/O3: do not import their artifact trees or gates.

## Outcome

The demand is carried through refinement, planning (ONE explicit approval) and implementation (final validation and the existing code review) in one evolving `features/NNN-slug/PLAN.md`, with one progress table kept in chat. The flow stops at every operator decision and never commits, pushes, merges or publishes automatically.

## Stage map

| Stage | Skill | Entry condition | Exit evidence |
|-------|-------|-----------------|---------------|
| refine | `adt-delivery-refine` | Step 0 passed | PLAN.md refinement content, triage audit table, ledger `refine=done` |
| plan | `adt-delivery-plan` | Ledger `refine=done` | Complete plan, explicit approval recorded, ledger `plan=approved` |
| implement | `adt-delivery-implement` | Ledger `plan=approved` and `Mode: full` | Validation and review evidence, ledger `implement=done` |

Stages run strictly in this order. Each one runs as its stage skill: the coordinator never does stage work itself, and no stage can be skipped. "In proportion" may shorten the depth of refinement, never skip the stage. The `Stage preconditions` line of each stage skill and the preflight (`references/step0.md`) enforce these entry conditions.

## Terminal outcomes

Apply the shared `Flow terminal contract` in `skills/_shared/skills-catalog/CATALOG.md`, as mapped for this skill in `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/HANDOFF.md`: `done`, `blocked`, `failed`, `open_question`. Never report `done` without evidence.

## Analysis-only mode

When the operator asks only for an analysis, diagnosis or assessment, record `Mode: analysis` in the Operational record, run Step 0 and the refine stage, then stop after refine with a findings report. The report separates facts, inferences and suggestions, with `file:line` references, and states the outcome. Do not draft or request plan approval. Offer to continue to planning; if the operator accepts, set `Mode: full` and route to plan. If the request is ambiguous between analysis and delivery, ask once before routing. Outcome mapping: `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/HANDOFF.md`.

## Flow contract: reads, writes, where, when

- **Reads:** repository instructions, `{{TOOLKIT_ROOT}}/skills/_shared/agents/LANGUAGE.md`, the feature's existing `PLAN.md` and state.
- **Writes:** nothing itself; the stage skills write the plan, its Operational record and code.
- **Where:** feature directory per `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/STORAGE-FEATURE.md`.
- **When to use:** end-to-end delivery or resume; for a single stage, call that stage skill directly.

## Lazy-load (only when needed)

| When | Path |
|------|------|
| Command playbook (step discovery after Step 0) | `{{TOOLKIT_ROOT}}/skills/adt-delivery-flow/references/command.md` |
| Blocking start, model choice, preflight | `{{TOOLKIT_ROOT}}/skills/adt-delivery-flow/references/step0.md` |
| Language surfaces | `{{TOOLKIT_ROOT}}/skills/_shared/agents/LANGUAGE.md` |
| Caveman Mode (if active) | `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md` - **exempt during refine and plan; Lite otherwise** |
| Triage, routing, split, resume | `{{TOOLKIT_ROOT}}/skills/adt-delivery-flow/references/routing.md` |
| Storage root, feature selection, split | `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/STORAGE-FEATURE.md` |
| Approval, amendment, resume | `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/PLAN-LIFECYCLE.md` |
| Specialist triage and audit table | `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/TRIAGE.md` |
| Progress table rows | `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/DISPLAY.md` |
| Terminal outcomes and handoff | `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/HANDOFF.md` |
| Refinement | `{{TOOLKIT_ROOT}}/skills/adt-delivery-refine/SKILL.md` |
| Planning | `{{TOOLKIT_ROOT}}/skills/adt-delivery-plan/SKILL.md` |
| Implementation | `{{TOOLKIT_ROOT}}/skills/adt-delivery-implement/SKILL.md` |
| Selecting specialists when warranted | `{{TOOLKIT_ROOT}}/skills/_shared/agents/ROSTER.md` |
| Delegating; mandatory when subagents capability is `native` | `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md` |

**Never by default:** do not preload `references/command.md` before the gates; load one reference per step. This rule does not apply to `references/step0.md`: Step 0 loads first and is mandatory, and no reading order excuses skipping it.

**Never by default:** load every stage skill at once.

## Process

After Step 0: **Read `references/command.md`** for ordered step discovery; then load one reference per step.

### Step -1b - Caveman Mode (Lite cap; exempt during refine and plan)
1. Preferences are read and the notices are shown in Step 0 (`references/step0.md`).
2. **Exemption.** While the refine or plan stage runs, including the coordinator's chat for that stage, caveman compression is fully suspended for chat output, questions, findings, drafts, and the prompts and receipts of specialists spawned in that stage. This holds regardless of `caveman_mode` and `caveman_level`. No caveman notice is shown then, and no caveman command lifts the exemption during those stages. Participation: `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md`.
3. Outside refine and plan: if `caveman_mode` is true, apply the **Lite** cap with the prefs `caveman_level` (Lite never escalates).
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) outside those stages.
5. Auto-Clarity + never-compress gates/drafts/paths per `CAVEMAN.md`.

### Steps

1. **Resolve storage and feature.** Follow `STORAGE-FEATURE.md`; locate existing artifacts before allocating NNN; preserve unrelated work.
2. **Triage the demand.** `references/routing.md`; `TRIAGE.md` for security signals. Decide full or analysis mode (Analysis-only mode above).
3. **Route to refinement.** `adt-delivery-refine`. It runs its own entry preflight after it writes the Operational record (`references/routing.md`).
4. **Route to planning, one approval.** Only after ledger `refine=done`: run the `plan` preflight (`references/step0.md`), then `adt-delivery-plan`; `references/routing.md`; `PLAN-LIFECYCLE.md`. Continue to planning in the same invocation only when no material decision is pending.
5. **Route to implementation.** Only after ledger `plan=approved` and `Mode: full`: run the `implement` preflight, then `adt-delivery-implement`, which asks branch, cadence and review mode.
6. **Show progress.** Render the one flow table per `DISPLAY.md` at every display point; the chat table is never written into `PLAN.md`.
7. **Resume and report the outcome.** `references/routing.md`; `HANDOFF.md`.

## Must not

- Treat approval of the refinement as approval to implement, or skip the single plan approval.
- Do the stage work itself instead of routing to the stage skills.
- Route to a stage before its entry condition holds or its preflight passes.
- Skip Step 0, or treat a saved preference as the model answer.
- Load every stage skill or specialist reference at once.
- Create independent plans without the operator's agreement.
- Commit, push, merge or publish automatically.
- Draw a second progress table while a stage skill runs.
- Fall back from global to local storage.
- Use cold reviewers (cold-critic, cold-reader) or impose a token budget.
- Write the chat progress table into PLAN.md.

## Handoff

| Situation | Next |
|-----------|------|
| Flow done | Report the result. Commit, push and PR only on the operator's specific request. |
| Analysis findings delivered | Offer planning and wait. If accepted: set `Mode: full`, run the `plan` preflight, continue at step 4. |
| A stage blocked, failed or waiting | State the stage and the cause or the question; wait. |
| Resume | Run Step 0 again, then start from the selected plan's Operational record. |

```text
adt-delivery-flow - resume features/004-export-profile
```

Paths in handoffs are portable: `features/NNN-slug/PLAN.md` (global: prefix `sdd/<repo-id>/`).
