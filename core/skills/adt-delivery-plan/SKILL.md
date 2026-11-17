---
name: adt-delivery-plan
description: Turn an ADT delivery refinement into one complete, approvable execution plan in the same PLAN.md. Use when invoking adt-delivery-plan (host examples /adt-delivery-plan, $adt-delivery-plan, use skill adt-delivery-plan) or when routed by adt-delivery-flow.
---

## STOP - Read before ANY tool call

Read `_shared/skill-boilerplate.md` first. It holds the guardrails read, the session gate rule, the user `sim` rule, the one-step rule, the gate check, and the user chat language rule. The steps below are skill-specific only.

Every text, question, draft, receipt and code comment this skill writes follows `{{TOOLKIT_ROOT}}/rules/ai-stealth.mdc`.

ADT exceptions to the Classic gates: this flow keeps one evolving `features/NNN-slug/PLAN.md`, one explicit plan approval (`{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/PLAN-LIFECYCLE.md`) instead of per-step `step_confirmed`, and its own cadence. The draft `PLAN.md` may be created and refined before approval. Everything else in the boilerplate still applies.

**Step 0 is blocking.** When run directly (not routed by `adt-delivery-flow` in this same run), run Step 0 first: `{{TOOLKIT_ROOT}}/skills/adt-delivery-flow/references/step0.md`. When routed, Step 0 was already done.

# Skill: adt-delivery-plan

## Trigger

Invoke `adt-delivery-plan` (host forms: `/adt-delivery-plan`, `$adt-delivery-plan`, `use skill adt-delivery-plan`).

**Negative signal:** applies as defined in `_shared/skill-boilerplate.md`; the skill-specific signals are listed below.

- Invoke when the operator asks to plan a refined demand for the ADT delivery flow, or when `adt-delivery-flow` routes to planning.
- Do not invoke to implement, commit or publish an approved plan; that belongs to `adt-delivery-implement`.

## Outcome

- The same `PLAN.md` holds a complete plan: steps, validation (criterion -> test map), risks, acceptance coverage.
- The planner self-check is done; ONE explicit approval of the full plan is requested and recorded as one line.
- No implementation, commit or publish happens here. Invoked by `adt-delivery-flow`, it returns control to the coordinator.

Stage preconditions: Step 0 passed and ledger `refine=done`; checked in prose at step 2 of Process.

## Terminal outcomes

Apply the shared `Flow terminal contract` in `skills/_shared/skills-catalog/CATALOG.md`, as mapped for this skill in `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/HANDOFF.md`: `done`, `blocked`, `failed`, `open_question`. Never report `done` without evidence.

## Flow contract: reads, writes, where, when

- **Reads:** repository instructions, `LANGUAGE.md`, the selected `PLAN.md` with its refinement, the memory-bank files and guideline files named in step 4, relevant source.
- **Writes:** the selected `PLAN.md` (normative content and the approval line in the operational record); an independent plan only after an agreed split.
- **Where:** feature directory per `STORAGE-FEATURE.md`.
- **When to use:** the refinement is clear enough to plan, or a plan must be completed or amended.

## Lazy-load (only when needed)

| When | Path |
|------|------|
| Command playbook (step discovery after Step 0) | `{{TOOLKIT_ROOT}}/skills/adt-delivery-plan/references/command.md` |
| Language surfaces | `{{TOOLKIT_ROOT}}/skills/_shared/agents/LANGUAGE.md` |
| Caveman Mode | exempt in this stage, never compressed; see Step -1b (`{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md`) |
| Storage root, feature selection, plan selection, split, memory-bank root | `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/STORAGE-FEATURE.md`; `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/MEMORY-BANK.md` ("Path resolution") |
| Guideline map (mandatory at step 4) | `{{TOOLKIT_ROOT}}/skills/adt-delivery-refine/references/clarify.md` ("Guidelines to read") |
| Amendment and renewed approval | `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/PLAN-LIFECYCLE.md` |
| Shaping the plan | `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/PLAN-TEMPLATE.md` |
| Specialist triage | `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/TRIAGE.md` |
| Planning rules, validation map, documentation language | `{{TOOLKIT_ROOT}}/skills/adt-delivery-plan/references/plan-content.md` |
| Progress table rows | `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/DISPLAY.md` (mandatory read at step 3) |
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

1. **Resolve storage and select plan.** Follow `STORAGE-FEATURE.md`. If the selected plan is absent, stop and request the intended input or refinement; do not create a substitute.
2. **Entry check (prose).** The Stage ledger of the selected plan reads `refine=done`. If not, report the missing refinement and stop; do not draft steps.
3. **Show progress (display point 1).** Read `DISPLAY.md` now and draw the plan stage table at Start. When invoked by `adt-delivery-flow`, do not draw it: the flow's table is the only one drawn. Redraw at each display point; the chat table is never written into `PLAN.md`.
4. **Context (mandatory).**
   - Memory-bank: if the Evidence has a `Memory-bank:` line, reuse it. Otherwise check `bank_root` and read it as `adt-delivery-refine` step 4 does (five files, selectively, or `absent`), then record the line.
   - Guidelines: if the Evidence has a `Guidelines:` line, reuse it and read only the paths it lacks for the areas this plan touches, from the map in `adt-delivery-refine/references/clarify.md`; append them to the line. Otherwise read the base and applicable files from that map and record the line.
5. **Inspect source, specialist triage.** Read relevant source only. Triage per `TRIAGE.md`; delegate per `ROSTER.md` and `SPAWN.md` only when warranted, with a local fallback.
6. **Draft steps, validation and risks.** Shape with `PLAN-TEMPLATE.md` and `references/plan-content.md`. Keep normative content separate from operational status. Each step cites its criteria and guideline files; Validation maps every criterion to its expected test. If a step writes to docs or a README, ask the documentation-language question now (`references/plan-content.md`, "Documentation language") and record the answer in that step.
7. **Planner self-check.** Targeted check in `references/plan-content.md`. Not a cold review and not a review loop.
8. **Present the plan and ask one approval.** Show the complete plan, request ONE explicit approval for its full scope, and record it as one free line in the Operational record (approver, date, scope). Set `Stage ledger` to `plan=approved` only when that explicit approval is recorded; a question, a review or silence leaves `plan=pending`. Resolve any open material question first.
9. **Outcome and handoff.** Apply `HANDOFF.md`. Direct invocation: redraw the table at close (display point 6). Then the handoff below.

## Must not

- Implement, commit or publish.
- Create a substitute plan when the selected plan is missing.
- Infer approval from silence, a review or a refinement approval.
- Set `plan=approved` without the recorded explicit approval.
- Request approval while a material question is open.
- Add a separate reviewer or review loop.
- Fall back from global to local storage.
- Use cold reviewers (cold-critic, cold-reader) or impose a token budget.
- Write the chat progress table into `PLAN.md`.

## Handoff

| Situation | Next |
|-----------|------|
| Approved and invoked directly | `adt-delivery-implement - <portable-plan-path>` |
| Invoked by `adt-delivery-flow` | Return control to the coordinator |
| Not approved, or open question | Stay in this skill; ask once and wait |

```
adt-delivery-implement - features/004-export-profile/PLAN.md
```

Paths are portable: `features/NNN-slug/PLAN.md` (global: prefix `sdd/<repo-id>/`).
