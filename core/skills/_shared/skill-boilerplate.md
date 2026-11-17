# Skill boilerplate - shared gates

Every skill loads this file before its first tool call. The skill body adds only its own steps. Do not copy these rules into `SKILL.md`; point to this file instead.

## STOP - Read before ANY tool call

1. Read `{{GUARDRAILS_PATH}}` (always mandatory).
2. Session state: consult `_shared/sdd-artifacts/SESSION.md` only when the active consumer's contract explicitly uses session helpers. Classic SDD and Orchestrated Delivery do not use it as an execution prerequisite. Use `_shared/sdd-artifacts/INDEX.md` for conditional references.
3. If the relevant gate is not approved: **STOP** and ask the user in the **user chat language** (`_shared/agents/LANGUAGE.md`); gate ids and answer rule: `_shared/agents/QUESTIONS.md`. Do **NOT** Write or run Shell.
4. Classic `sdd-develop`: follow the approved PLAN cadence. In `step_by_step`, stop after one completed step; in `continuous`, advance through eligible steps until completion or a real blocker. Before each next step, re-check PLAN approval, dependencies, scope, acceptance, and relevant evidence; SESSION flags and claims are not prerequisites. O3 remains serial, one PLAN step per child, with the parent reconciling the result before dispatching the next step.
5. The skill body is **English**. User-facing prompts follow the **user chat language** (`_shared/agents/LANGUAGE.md`).

### Step -1 - Gate check (silent)

Verify silently, before continuing, the items that apply to the current action:

- guardrails read
- SESSION.md loaded when the active consumer explicitly requires session helpers
- PIPELINE.md read, only when sdd-artifacts/INDEX.md requires it (SDD skills; required for orchestrate-*)
- User gave a `confirm` answer for the current action, when the action writes or runs a gated step

Do not print a checklist. Report in chat only when a check fails: list only the failing items and STOP.

## Negative signal

Do not activate a skill when the request lacks one of its positive signals or its required context. Topic similarity or an isolated keyword alone is insufficient.
