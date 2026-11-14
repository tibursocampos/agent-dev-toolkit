---
name: adt-delivery-plan
description: Turn an ADT delivery refinement into one complete, approvable execution plan in the same PLAN.md. Use when invoking adt-delivery-plan (host examples /adt-delivery-plan, $adt-delivery-plan, use skill adt-delivery-plan) or when routed by adt-delivery-flow.
---

## STOP - Read before ANY tool call

Read `_shared/skill-boilerplate.md` first. It holds the guardrails read, the session gate rule, the user `sim` rule, the one-step rule, the gate check, and the user chat language rule. The steps below are skill-specific only.

ADT exceptions to the Classic gates: this flow keeps one evolving `features/NNN-slug/PLAN.md`, one explicit plan approval (`{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/PLAN-LIFECYCLE.md`) instead of per-step `step_confirmed`, and its own cadence. The draft `PLAN.md` may be created and refined before approval. Everything else in the boilerplate still applies.

# Skill: adt-delivery-plan

## Trigger

Invoke `adt-delivery-plan` (host forms: `/adt-delivery-plan`, `$adt-delivery-plan`, `use skill adt-delivery-plan`).

**Negative signal:** applies as defined in `_shared/skill-boilerplate.md`; the skill-specific signals are listed below.

- Invoke when the operator asks to plan a refined demand for the ADT delivery flow, or when `adt-delivery-flow` routes to planning.
- Do not invoke to implement, commit or publish an approved plan; that belongs to `adt-delivery-implement`.

## Outcome

- The same `PLAN.md` holds a complete plan: steps, validation, risks, acceptance coverage.
- The planner self-check is done; ONE explicit approval of the full plan is requested and recorded.
- No implementation, commit or publish happens here. Invoked by `adt-delivery-flow`, it returns control to the coordinator.

## Terminal outcomes

Apply the shared `Flow terminal contract` in `skills/_shared/skills-catalog/CATALOG.md`, as mapped for this skill in `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/HANDOFF.md`: `done`, `blocked`, `failed`, `open_question`. Never report `done` without evidence.

## Flow contract: reads, writes, where, when

- **Reads:** repository instructions, `LANGUAGE.md`, the selected `PLAN.md` with its refinement, relevant source.
- **Writes:** the selected `PLAN.md` (normative content and the approval record in the operational record); an independent plan only after an agreed split.
- **Where:** feature directory per `STORAGE-FEATURE.md`.
- **When to use:** the refinement is clear enough to plan, or a plan must be completed or amended.

## Lazy-load (only when needed)

| When | Path |
|------|------|
| Command playbook (step discovery after gates) | `{{TOOLKIT_ROOT}}/skills/adt-delivery-plan/references/command.md` |
| Language surfaces | `{{TOOLKIT_ROOT}}/skills/_shared/agents/LANGUAGE.md` |
| Caveman Mode (if active) | `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md` - **Lite cap** |
| Storage root, feature selection, plan selection, split | `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/STORAGE-FEATURE.md` |
| Approval record, material change, amendment | `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/PLAN-LIFECYCLE.md` |
| Shaping the plan | `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/PLAN-TEMPLATE.md` |
| Specialist triage and audit table | `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/TRIAGE.md` |
| Planning rules | `{{TOOLKIT_ROOT}}/skills/adt-delivery-plan/references/plan-content.md` |
| Progress table rows | `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/DISPLAY.md` |
| Terminal outcomes and handoff | `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/HANDOFF.md` |
| Selecting specialists when warranted | `{{TOOLKIT_ROOT}}/skills/_shared/agents/ROSTER.md` |
| Delegating when available | `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md` |

**Never by default:** do not preload `references/command.md` before the gates; load one reference per step.

## Process

After gates: **Read `references/command.md`** for ordered step discovery; then load one reference per step.

### Step -1b - Caveman Mode (Lite cap)
1. Read `{{SDD_ROOT}}/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full", "orchestrator_mode": "adaptive", "artifact_language": null }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md`; apply **Lite** participation cap + prefs `caveman_level` (Lite skills never escalate); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) during the session.
5. Auto-Clarity + never-compress gates/drafts/paths per `CAVEMAN.md`.

1. **Resolve storage and select plan.** Follow `STORAGE-FEATURE.md`. If the selected plan is absent, stop and request the intended input or refinement; do not create a substitute.
2. **Inspect source, run specialist triage.** Read relevant source only. Triage per `TRIAGE.md`; delegate per `ROSTER.md` and `SPAWN.md` only when warranted, with a local fallback.
3. **Draft steps, validation and risks.** Shape with `PLAN-TEMPLATE.md` and `references/plan-content.md`. Keep normative content separate from operational status.
4. **Planner self-check.** Targeted check in `references/plan-content.md`. Not a cold review and not a review loop.
5. **Show progress.** Render the progress table(s) per `DISPLAY.md` at every display point; the chat table is never written into `PLAN.md`. When invoked by `adt-delivery-flow`, do not draw this table: the flow's own table is the only one drawn (see `DISPLAY.md`).
6. **Present the plan and ask one approval.** Show the complete plan, request ONE explicit approval for its full scope, and record it per `PLAN-LIFECYCLE.md`. Resolve any open material question first.
7. **Outcome and handoff.** Apply `HANDOFF.md`: terminal outcome, then the handoff below.

## Must not

- Implement, commit or publish.
- Create a substitute plan when the selected plan is missing.
- Infer approval from silence, a review or a refinement approval.
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
