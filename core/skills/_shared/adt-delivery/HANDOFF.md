# ADT delivery - terminal outcomes and handoff

Outcome states come from the shared contract `{{TOOLKIT_ROOT}}/skills/_shared/skills-catalog/CATALOG.md`, heading `Flow terminal contract`. This file maps those states to the adt-delivery skills; it does not redefine them.

## Terminal outcomes per skill

| Skill | done | blocked | failed | open_question |
|-------|------|---------|--------|---------------|
| adt-delivery-refine | refinement recorded in the plan and handoff to planning offered | missing input, decision or access; unresolved items marked in the plan | analysis could not be completed; limitation recorded | one material question awaits the operator; silence leaves it blocked |
| adt-delivery-plan | complete plan presented and explicit approval recorded | open material question, or missing refinement or input plan | plan self-check found a contradiction that could not be resolved | approval or decision awaits the operator |
| adt-delivery-implement | all steps COMPLETED, final validation passed, review report written, evidence recorded | dependency, approval invalidated, unplanned scope, or check unavailable; recorded with next action | a step or validation failed; evidence and bounded recovery recorded, no automatic retry | branch, cadence, review mode, scope change or approval awaits the operator |
| adt-delivery-flow | the stage requested by the operator reached its own done | inherited from the active stage skill, with that stage named | inherited from the active stage skill, with that stage named | inherited from the active stage skill, with that stage named |
| adt-delivery-flow, analysis mode | refinement recorded (`refine=done`) and the findings report delivered, with the planning offer | missing input, decision or access; the limitation is named in the report | analysis could not be completed; limitation recorded | analysis or delivery intent awaits the operator; ask once |

- Never report `done` without evidence.
- Never present partial review, failed or unavailable validation as success.
- A completed step never implies delivery complete.

## Handoff

Plan paths are portable. Use one of:

- `features/NNN-slug/PLAN.md`
- global storage: `sdd/<repo-id>/features/NNN-slug/PLAN.md`
- independent split plan: `features/NNN-slug/plans/<unit-or-repo-slug>/PLAN.md`

| Situation | Next |
|-----------|------|
| refine done, invoked directly | `adt-delivery-plan - <portable-plan-path>` |
| refine invoked by adt-delivery-flow | return control to the coordinator; no handoff text to the operator |
| plan approved, invoked directly | `adt-delivery-implement - <portable-plan-path>`; branch, cadence and review mode are asked there |
| plan approved after an agreed split, invoked directly | `adt-delivery-implement - <portable-plan-path>` once per independent plan, one line each; the feature-root plan holds the shared decisions and is not implemented itself |
| plan not approved, or open question | stay in `adt-delivery-plan`; ask once and wait |
| analysis findings delivered, operator accepts planning | set `Mode: full` in the Operational record, check that the Stage ledger reads `refine=done`, then continue to `adt-delivery-plan - <portable-plan-path>` |
| analysis findings delivered, no acceptance | stop; the analysis outcome is `done` with the findings report as evidence |
| implement done | report the result; commit, push and PR only on the operator's specific request (`commit`, `push`, `open-github-pr` skills) |
| implement blocked or failed | state the cause and the exact input or change that resolves it; do not retry the same transition automatically |
| code review already ran inside implement closeout | do not suggest running it again unless the operator asks |

Example:

```
adt-delivery-implement - features/004-export-profile/PLAN.md
```

## Resume

- Any skill resumed after interruption starts from the selected plan's Operational record and `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/PLAN-LIFECYCLE.md`, reconciling state before continuing.
