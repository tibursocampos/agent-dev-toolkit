# orchestrate-deliver — reference index

Extended detail for `skills/orchestrate-deliver/SKILL.md`. **Do not Read this file for procedural detail** when a section file exists — load `references/<section>.md` per Process step or Reference routing.

Contract: `SKILL-REFERENCE-RETRIEVAL.md` (`SR-LAZY-REFERENCE`).

| Section | Path |
|---------|------|
| Command playbook (step discovery) | `references/command.md` |
| Preconditions / Step 0 / backlog siblings STOP | `references/preconditions.md` |
| Mode comparison / choose série vs paralelo | `references/mode-selection.md` |
| Per-story paths / contracts / Task child skeleton | `references/per-story-contracts.md` |
| Approval gates / approval answers | `references/approval-gates.md` |
| CONTINUITY / handoff / cross-artifact / invoke strings | `references/continuity-handoff.md` |
| Caveman / resolve storage / context pressure | `references/process-common.md` |
| Boundaries / Must not / exclusions | `references/boundaries-must-not.md` |
| CHANGE gate / brownfield vs greenfield / TASKS | `references/continuity-handoff.md` § Cross-artifact analyze + `CHANGE-CONTRACT.md` |
| Preflight PRD→PLAN→CHANGE (REQ-004 / CA4) | `references/preflight-prd-plan-change.md` |

Brownfield requires `features/NNN-slug/CHANGE.md` (ADDED \| MODIFIED \| REMOVED); greenfield must not force an empty CHANGE stub.
Before O3 handoff, run `Invoke-PrdPlanChangePreflight.ps1` (see `references/preflight-prd-plan-change.md`).
