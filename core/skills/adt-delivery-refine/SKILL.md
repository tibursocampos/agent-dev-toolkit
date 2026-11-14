---
name: adt-delivery-refine
description: Refine a demand into the evolving ADT delivery PLAN.md covering outcome, scope, evidence, acceptance criteria and specialist triage. Use when invoking adt-delivery-refine (host examples /adt-delivery-refine, $adt-delivery-refine, use skill adt-delivery-refine) or when routed by adt-delivery-flow.
---

## STOP - Read before ANY tool call

Read `_shared/skill-boilerplate.md` first. It holds the guardrails read, the session gate rule, the user `sim` rule, the one-step rule, the gate check, and the user chat language rule. The steps below are skill-specific only.

ADT exceptions to the Classic gates: this flow keeps one evolving `features/NNN-slug/PLAN.md`, one explicit plan approval (`{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/PLAN-LIFECYCLE.md`) instead of per-step `step_confirmed`, and its own cadence. The draft `PLAN.md` may be created and refined before approval. Everything else in the boilerplate still applies.

**Step 0 is blocking.** When run directly (not routed by `adt-delivery-flow` in this same run), run Step 0 first: `{{TOOLKIT_ROOT}}/skills/adt-delivery-flow/references/step0.md`. When routed, Step 0 was already done.

# Skill: adt-delivery-refine

## Trigger

Invoke `adt-delivery-refine` (host forms: `/adt-delivery-refine`, `$adt-delivery-refine`, `use skill adt-delivery-refine`).

**Negative signal:** applies as defined in `_shared/skill-boilerplate.md`; the skill-specific signals are listed below.

- Invoke when the operator asks to refine a demand for the ADT delivery flow, or when `adt-delivery-flow` routes to refinement.
- Not for plan approval or implementation: those belong to `adt-delivery-plan` and `adt-delivery-implement`.

## Outcome

- `features/NNN-slug/PLAN.md` Normative content updated with the refinement: outcome, scope and exclusions, evidence, decisions, acceptance criteria, impact, specialist triage table.
- Refinement is not implementation approval.
- Invoked directly, it stops with the planning handoff; invoked by `adt-delivery-flow`, it returns control to the coordinator.
- Analysis mode (`Mode: analysis`): it stops after refinement with a findings report; see `{{TOOLKIT_ROOT}}/skills/adt-delivery-flow/SKILL.md`, "Analysis-only mode".

Stage preconditions: Step 0 passed (`{{TOOLKIT_ROOT}}/skills/adt-delivery-flow/SKILL.md`, "Stage map"); enforced by the `refine` preflight at entry.

## Terminal outcomes

Apply the shared `Flow terminal contract` in `skills/_shared/skills-catalog/CATALOG.md`, as mapped for this skill in `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/HANDOFF.md`: `done`, `blocked`, `failed`, `open_question`. Never report `done` without evidence.

## Flow contract: reads, writes, where, when

- **Reads:** repository instructions, `{{TOOLKIT_ROOT}}/skills/_shared/agents/LANGUAGE.md`, the feature's existing `PLAN.md`, relevant source.
- **Writes:** only the feature's `PLAN.md` (draft Normative content, Operational record lines written in step 1 and step 5).
- **Where:** feature directory resolved per `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/STORAGE-FEATURE.md`.
- **When to use:** a demand needs clarification before planning, or the first stage is invoked manually.

## Lazy-load (only when needed)

| When | Path |
|------|------|
| Command playbook (step discovery after Step 0) | `{{TOOLKIT_ROOT}}/skills/adt-delivery-refine/references/command.md` |
| Language surfaces | `{{TOOLKIT_ROOT}}/skills/_shared/agents/LANGUAGE.md` |
| Caveman Mode | exempt in this stage, never compressed; see Step -1b (`{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md`) |
| Storage root, feature selection, split | `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/STORAGE-FEATURE.md` |
| Specialist triage and audit table | `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/TRIAGE.md` |
| Refinement rules | `{{TOOLKIT_ROOT}}/skills/adt-delivery-refine/references/clarify.md` |
| Shaping the plan | `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/PLAN-TEMPLATE.md` |
| Progress table rows | `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/DISPLAY.md` |
| Terminal outcomes and handoff | `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/HANDOFF.md` |
| Selecting specialists when warranted | `{{TOOLKIT_ROOT}}/skills/_shared/agents/ROSTER.md` |
| Delegating; mandatory when subagents capability is `native` | `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md` |

**Never by default:** do not preload `references/command.md` before the gates; load one reference per step.

## Process

After Step 0: **Read `references/command.md`** for ordered step discovery; then load one reference per step.

### Step -1b - Caveman Mode (exempt: never compress)
1. This stage is exempt. Caveman compression is fully suspended for chat output, questions, findings, drafts, and the prompts and receipts of specialists spawned here, regardless of `caveman_mode` and `caveman_level`.
2. Do not show the caveman activation notice. No caveman command lifts the exemption while this stage runs.

### Steps

1. **Resolve storage and feature.** Apply `STORAGE-FEATURE.md`: use the existing feature or allocate the next NNN; never fall back from global to local storage. Then write or update the Operational record lines of the selected `PLAN.md`: `Mode`, `Subagents`, `Model choice` and `Stage ledger` (`{{TOOLKIT_ROOT}}/skills/adt-delivery-flow/references/step0.md`, "Recorded values"). A new plan starts with `refine=pending, plan=pending, implement=pending`; an existing ledger is kept.
2. **Entry check.** Run the `refine` preflight (`{{TOOLKIT_ROOT}}/skills/adt-delivery-flow/references/step0.md`). Exit 1: report the `failures` list and stop.
3. **Specialist triage.** Follow `TRIAGE.md`: set the `needs_*` flags and nature, and write the six-row audit table in Decisions. Delegate only when warranted (`ROSTER.md`, `SPAWN.md`); otherwise use the in-parent fallback and say so.
4. **Clarify and gather evidence.** Follow `references/clarify.md`: inspect relevant source, keep request, facts, inferences and suggestions apart, and ask only material questions, grouped.
5. **Record in `PLAN.md`.** Follow `PLAN-TEMPLATE.md`: update Normative content in place, preserve prior decisions and Operational record progress, and mark unresolved items. Set `Stage ledger` to `refine=done` only when the refinement is complete and no material question is open.
6. **Show progress.** Render the refinement stage table per `DISPLAY.md` at every display point. The chat table is never written into `PLAN.md`. When invoked by `adt-delivery-flow`, do not draw this table: the flow's own table is the only one drawn (see `DISPLAY.md`).
7. **Outcome and handoff.** Follow `HANDOFF.md`: direct invocation ends with the planning handoff; flow invocation returns control; an open material question stays here until answered. In analysis mode (`Mode: analysis`), stop after step 5 with a findings report (facts, inferences and suggestions kept apart, with `file:line`); give no plan handoff and wait for the operator's answer to the planning offer.

## Must not

- Implement, approve or publish anything.
- Invent requirements or expand scope.
- Create extra story artifacts by default, or `ANALYSIS/`, `ARCH/`, `SEC/` folders.
- Treat specialist or reviewer suggestions as authorized scope.
- Preload unrelated repository context.
- Set `refine=done` while a material question is open.
- Fall back from global to local storage.
- Use cold reviewers (cold-critic, cold-reader) or impose a token budget.
- Write the chat progress table into `PLAN.md`.

## Handoff

| Situation | Next |
|-----------|------|
| refine done, invoked directly | `adt-delivery-plan - <portable-plan-path>` |
| refine done in analysis mode, invoked directly | findings report, then the offer to plan; wait |
| refine invoked by adt-delivery-flow | return control to the coordinator; no handoff text to the operator |
| open material question | stay in this skill, ask once and wait |

Example:

```
adt-delivery-plan - features/004-export-profile/PLAN.md
```

Plan paths are portable: `features/NNN-slug/PLAN.md` (global storage: prefix `sdd/<repo-id>/`).
