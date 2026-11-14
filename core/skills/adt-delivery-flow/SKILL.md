---
name: adt-delivery-flow
description: Coordinate an ADT delivery from demand through refinement, one approved plan, implementation and review. Use when invoking adt-delivery-flow (host examples /adt-delivery-flow, $adt-delivery-flow, use skill adt-delivery-flow).
---

## STOP - Read before ANY tool call

Read `_shared/skill-boilerplate.md` first. It holds the guardrails read, the session gate rule, the user `sim` rule, the one-step rule, the gate check, and the user chat language rule. The steps below are skill-specific only.

ADT exceptions to the Classic gates: this flow keeps one evolving `features/NNN-slug/PLAN.md`, one explicit plan approval (`{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/PLAN-LIFECYCLE.md`) instead of per-step `step_confirmed`, and its own cadence. The draft `PLAN.md` may be created and refined before approval. Everything else in the boilerplate still applies.

# Skill: adt-delivery-flow

## Trigger

Invoke `adt-delivery-flow` (host forms: `/adt-delivery-flow`, `$adt-delivery-flow`, `use skill adt-delivery-flow`).

**Negative signal:** applies as defined in `_shared/skill-boilerplate.md`; the skill-specific signals are listed below.

- Invoke when the operator asks to deliver a demand end to end with the ADT delivery flow, or to resume a feature of this flow.
- Separate from Classic SDD and O1/O2/O3: do not import their artifact trees or gates.

## Outcome

The demand is carried through refinement, planning (ONE explicit approval) and implementation (final validation and the existing code review) in one evolving `features/NNN-slug/PLAN.md`, with one progress table kept in chat. The flow stops at every operator decision and never commits, pushes, merges or publishes automatically.

## Terminal outcomes

Apply the shared `Flow terminal contract` in `skills/_shared/skills-catalog/CATALOG.md`, as mapped for this skill in `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/HANDOFF.md`: `done`, `blocked`, `failed`, `open_question`. Never report `done` without evidence.

## Flow contract: reads, writes, where, when

- **Reads:** repository instructions, `{{TOOLKIT_ROOT}}/skills/_shared/agents/LANGUAGE.md`, the feature's existing `PLAN.md` and state.
- **Writes:** nothing itself; the stage skills write the plan and code.
- **Where:** feature directory per `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/STORAGE-FEATURE.md`.
- **When to use:** end-to-end delivery or resume; for a single stage, call that stage skill directly.

## Lazy-load (only when needed)

| When | Path |
|------|------|
| Command playbook (step discovery after gates) | `{{TOOLKIT_ROOT}}/skills/adt-delivery-flow/references/command.md` |
| Language surfaces | `{{TOOLKIT_ROOT}}/skills/_shared/agents/LANGUAGE.md` |
| Caveman Mode (if active) | `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md` - **Lite cap** |
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
| Delegating when available | `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md` |

**Never by default:** do not preload `references/command.md` before the gates; load one reference per step.

**Never by default:** load every stage skill at once.

## Process

After gates: **Read `references/command.md`** for ordered step discovery; then load one reference per step.

### Step -1b - Caveman Mode (Lite cap)
1. Read `{{SDD_ROOT}}/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full", "orchestrator_mode": "adaptive", "artifact_language": null }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md`; apply **Lite** participation cap + prefs `caveman_level` (Lite skills never escalate); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) during the session.
5. Auto-Clarity + never-compress gates/drafts/paths per `CAVEMAN.md`.

### Steps

1. **Resolve storage and feature.** Follow `STORAGE-FEATURE.md`; locate existing artifacts before allocating NNN; preserve unrelated work.
2. **Triage the demand.** `references/routing.md`; `TRIAGE.md` for security signals.
3. **Route to refinement.** `adt-delivery-refine`; continue to planning in the same invocation when no material decision is pending (`references/routing.md`).
4. **Route to planning, one approval.** `adt-delivery-plan`; `references/routing.md`; `PLAN-LIFECYCLE.md`.
5. **Route to implementation.** After approval, `adt-delivery-implement` asks branch, cadence and review mode.
6. **Show progress.** Render the one flow table per `DISPLAY.md` at every display point; the chat table is never written into `PLAN.md`.
7. **Resume and report the outcome.** `references/routing.md`; `HANDOFF.md`.

## Must not

- Treat approval of the refinement as approval to implement, or skip the single plan approval.
- Do the stage work itself instead of routing to the stage skills.
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
| A stage blocked, failed or waiting | State the stage and the cause or the question; wait. |
| Resume | Start again from the selected plan's Operational record. |

```text
adt-delivery-flow - resume features/004-export-profile
```

Paths in handoffs are portable: `features/NNN-slug/PLAN.md` (global: prefix `sdd/<repo-id>/`).
