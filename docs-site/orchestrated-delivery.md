---
title: Orchestrated Delivery
---

# Orchestrated Delivery

Use Orchestrated Delivery when analysis across stories, specialist questions, or coordinated execution will help. Classic SDD remains available directly for a clear single feature. Each `adt-orchestrate-*` skill owns its detailed procedure; [Using skills](using-skills.md) explains how to invoke them.

## Flow

| Phase | Skill | Result |
|---|---|---|
| O1 — Analyze | `adt-orchestrate-analyze` | Proportional investigation and justified stories. Specialists and analysis notes are used only for concrete questions. |
| O2 — Deliver | `adt-orchestrate-prepare` | PRD and executable PLAN for each selected story. Drafting and saving are preparation. |
| O3 — Develop (optional) | `adt-orchestrate-implement` | Serial PLAN-step queue; one child per step and each result reconciled before the next dispatch. |

Before implementation, O2 presents the complete PLAN or explicitly listed PLAN set for one approval. New approval is needed only when behavior, acceptance, scope, access, or an implementation decision changes materially. A material open question blocks only affected work; minor questions remain visible and independent stories can continue.

## Context and artifacts

Memory Bank, CONTINUITY, CHANGE, TASKS, and specialist sidecars are optional context. New work does not require creating them; resumed work does not require converting, synchronizing, or deleting them. Brownfield classification alone does not require mirrored architecture notes. Record material decisions in FEATURE/STORY/PRD/PLAN, or create a separate analysis artifact when it adds useful evidence.

The PLAN is the only persisted implementation-progress source. O1, O2, and O3 each own one contextual chat table. Internal spec/plan/develop calls do not draw a competing table. The [architecture guide](architecture.md) describes the toolkit's shared contracts and their relationships.

O3 uses `step_by_step` or `continuous` cadence, but implementation remains serial: one PLAN step per child. Reconcile delivery and update the PLAN before dispatching the next step. SESSION flags and claims are not prerequisites. On resume, use persisted PLAN state and inspect partial work; do not repeat a completed step only because a receipt or session flag is absent.

## Closeout

Run the validation required by the approved PLAN and one substantive review. Reuse current evidence when it covers the same stack, command, and unchanged working tree. After an in-scope correction, rerun only checks it invalidated. Commit, push, PR, installation, and publication remain separate actions requiring their own authorization.

See [Using skills](using-skills.md) for invocation and session behavior.
