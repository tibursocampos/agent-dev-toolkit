# Canonical PLAN acquisition

Resolve the approved PLAN and requested step before implementation. Applies to direct Classic and to an O3 child using its parent's scoped handoff.

## Canonical path shape

| Valid | Invalid |
|---|---|
| `features/NNN-slug/USnn/PLAN/PLAN_NNN_*.md` (or `TSnn`) | Root or flat `PLAN/` |
| Manifest-resolved global feature path under `sdd/<repo-id>/features/.../PLAN/` | A path outside the resolved feature root |

Normalize separators, reject traversal, and ensure the resolved path stays inside the authorized feature root. Absolute paths may be used to read the workspace, but written artifact references and receipts use portable paths.

## Acquisition

1. Resolve invocation context once from the explicit current invocation or parent handoff. Generic parent coordination, `orchestrator_mode`, or sibling files do not change a direct invocation into O3.
2. Normalize the explicit artifact with `adt-read-sdd-artifact` in Classic layout, using the manifest-selected root, then read the canonical PLAN in place. Do not rewrite its structure to satisfy a validator or filename grammar.
3. Resolve the requested step and verify that it exists, its dependencies are completed, and its described scope and acceptance are clear enough to implement.
4. Confirm that the PLAN's explicit approval covers this outcome, scope, access, and implementation decision. Do not require a status token, hash, session flag, claim, separate per-step confirmation, or exact approval wording.
5. Use only the PLAN as the required step breakdown. Existing task checklists or sidecars are optional context unless the current invocation explicitly adopts a related checklist.
6. Resolve the selected cadence using `references/develop-modes.md`. Direct Classic may proceed through the approved scope in `continuous`; `step_by_step` stops after one completed step.
7. Preserve any external-access target and operation limits stated by the PLAN. Use `CLASSIC-EXTERNAL-ACCESS.md` where relevant; block if the required access boundary is unavailable. A fixture or receipt does not grant filesystem authority.

If the canonical PLAN is missing, use the shared `PIPELINE.md` missing-PLAN path; this skill does not create a PRD or PLAN. If the requested step is absent, a dependency is incomplete, approval does not cover it, or a material decision remains open, stop and identify the affected work and next action.

## O3 handoff

An O3 child receives one canonical PLAN path and one step from its parent. It implements only that step and returns the role-specific result from `RECEIPT.md`. The parent owns queue eligibility, serial dispatch, and the contextual table. SESSION flags and PLAN claims are not prerequisites for this skill.
