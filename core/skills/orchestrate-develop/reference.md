# orchestrate-develop — reference index

Extended detail for `skills/orchestrate-develop/SKILL.md`. **Do not Read this file for procedural detail** when a section file exists — load `references/<section>.md` per Process step or Reference routing.

Contract: `SKILL-REFERENCE-RETRIEVAL.md` (`SR-LAZY-REFERENCE`).

| Section | Path |
|---------|------|
| Command playbook (step discovery) | `references/command.md` |
| Preconditions / Step 0 / Step N refresh-light | `references/preconditions.md` |
| Anti-bypass checklist (CA5) | `references/anti-bypass.md` |
| Step queue / build queue / spawn child / Task skeleton | `references/step-queue-spawn.md` |
| Step 5.5 post-implement verifier (`verify_mode`) | `references/step-verifier.md` |
| Safe parallelism rules + process | `references/parallelism.md` |
| Execution modes (serial/parallel/manual; queue/claim) | `references/execution-modes.md` |
| plan-acquisition (REQ-008 / CA3) | `references/plan-acquisition.md` |
| Develop modes `continuous` \| `step_by_step` (007 REQ-009) | `references/develop-modes.md` |
| plan-contract markers + delivery-baseline (REQ-010) | `references/plan-contract.md` |
| CONTINUITY / handoff / stop conditions / Step N process | `references/continuity-handoff.md` |
| Contract reuse / boundaries / invoke strings | `references/contract-boundaries.md` |
| Caveman / resolve feature / PLAN set | `references/process-common.md` |
| Must not / exclusions | `references/must-not.md` |

Evidence (EVD/`STATE.md`, `validate-evidence`, Verifier ≠ O3): `references/step-queue-spawn.md` + `EVD-STATE-CONTRACT.md`.  
Post-implement verifier (`verify_mode`, read-only child): `references/step-verifier.md`.  
Living loop / TRACE (`validate-trace`): `references/step-queue-spawn.md` + `TRACE-ARCHIVE-CONTRACT.md`.

Develop contract (source of truth, not split): `skills/sdd-develop/SKILL.md` + `reference.md`.
