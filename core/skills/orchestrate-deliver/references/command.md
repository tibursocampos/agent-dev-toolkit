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
| 6 | Per-story `sdd-spec` then `sdd-plan` (reuse contracts) | `references/per-story-contracts.md` |
| 7 | Approval per story or batch (**sim**) | `references/approval-gates.md` |
| 8 | CONTINUITY + multi-path handoff (CHANGE cross-check) | `references/continuity-handoff.md` |
| 9 | Context pressure / resume | `references/process-common.md` § Context pressure |

**Must not (full):** `references/boundaries-must-not.md`. Develop handoffs: `SKILL.md` § Canonical develop handoffs.
