# orchestrate-deliver — command playbook

**Load after Step -1 gates.** Ordered step discovery without dumping `SKILL.md` Process (REQ-006 / CA3). Load **one** section file per step (`SKILL-REFERENCE-RETRIEVAL.md`).

| Step | Action | Lazy section / contract |
|------|--------|-------------------------|
| -1b | Caveman Lite when active | `references/process-common.md` § Caveman |
| 1 | Gate check; load PIPELINE + SESSION; STOP if unchecked | `PIPELINE.md`, `SESSION.md` |
| 1b | Resolve `invocation_context` (default `orchestrated`) | `INVOCATION-CONTEXTS.md` |
| 2 | Resolve feature + storage; STOP if FEATURE/CONTINUITY missing | `references/process-common.md` § Resolve feature |
| 3 | Step 0 Memory Bank Gate (`auto`) | `references/preconditions.md` § Step 0; `MEMORY-BANK.md` |
| 4 | Preconditions (approved backlog; required siblings) | `references/preconditions.md` |
| 5 | Choose mode série vs paralelo (ask; SPAWN) | `references/mode-selection.md`; `SPAWN.md` |
| 6 | Per story: story-file gate, `sdd-spec`, PRD contestation, `split-story-checklist` when medium or complex, then `sdd-plan`. An open question stops that story. | `references/per-story-contracts.md` |
| 7 | Approval per story or batch (**sim**) | `references/approval-gates.md` |
| 8 | CONTINUITY + multi-path handoff (CHANGE cross-check) | `references/continuity-handoff.md` |
| 9 | Durable progress handoff | `references/process-common.md` § Durable progress handoff |

**Must not (full):** `references/boundaries-must-not.md`. Develop handoffs: `SKILL.md` § Canonical develop handoffs.

## Live O2 progress

At the start of O2, render the `orchestrate-deliver` caller rows in `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/LIVE-STAGE-TABLE.md` in the chat language. Redraw the complete table after each stage and story-cycle checkpoint, including when a gate blocks or closes without success. In série mode, instantiate the story-cycle rows for the current eligible story, then advance them for the next story; retain completed rows as evidence of completed work. The table is chat-only and must not be copied into `CONTINUITY.md`.

Also render and refresh the cumulative O1/O2 checkpoint defined in that shared contract at O2 start, after material analysis or artifact/validation milestones, at each story-cycle boundary and approval gate, on block, and before final handoff/close. Carry forward still-relevant completed work, pending work, confirmed decisions/open questions, blockers and the next action. Reconcile status with canonical story artifacts and CONTINUITY before advancing or resuming. Keep this checkpoint chat-only; CONTINUITY remains the durable resumable checkpoint and O3 retains its separate PLAN-step ledger.

## Série queue continuation

After each story reaches its applicable approval gate, reload the canonical feature roster and reconcile any stale `CONTINUITY.md` checkpoint against the current `FEATURE.md`, story files, PRD/PLAN, and required siblings. Recompute the next eligible US/TS in canonical dependency/order sequence. Before its story-file gate, read that story's `STORY.md` and every `ANALYSIS/`, `ARCH/`, or `SEC/` sibling required by FEATURE flags (or brownfield rules), plus applicable `REFINE/` context and current feature context. Then run the next story's complete O2 cycle under its own readiness, owner, write, contestation, checklist, plan, validation, and approval gates.

Do not ask an extra “continue?” between eligible stories in série mode. Continue through all work already authorized, stopping only for a material blocker, a decision or approval gate that is due, or when all stories are closed. A prior story's approval never authorizes a later story's PRD/PLAN write. A blocked dependency stops only its affected branch; independently eligible stories remain in the queue. `sdd-develop`'s one-PLAN-step stop applies to the develop session, not to the O2 story queue.
