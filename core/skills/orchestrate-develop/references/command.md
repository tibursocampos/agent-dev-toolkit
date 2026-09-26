# orchestrate-develop — command playbook

**Load after Step -1 gates.** Ordered step discovery without dumping `SKILL.md` Process (REQ-006 / CA3). Load **one** section file per step (`SKILL-REFERENCE-RETRIEVAL.md`). Parent never writes app code.

| Step | Action | Lazy section / contract |
|------|--------|-------------------------|
| -1b | Caveman Full when active | `references/process-common.md` § Caveman |
| 1 | Gate check; **sim** before first spawn | `PIPELINE.md`, `SESSION.md` |
| 1b | Resolve `invocation_context` (default `orchestrated`); pass into children | `INVOCATION-CONTEXTS.md` |
| 2 | Resolve feature / PLAN set; **plan-acquisition**; path sanitize | `references/plan-acquisition.md`; `references/process-common.md` § Resolve feature / PLAN |
| 3 | Step 0 Memory Bank Gate; pass `bank_path` read-only | `references/preconditions.md` § Step 0 |
| 4 | Build step queue; execution mode + develop pacing (`continuous`\|`step_by_step`); present; wait **sim** | `references/execution-modes.md`; `references/develop-modes.md`; `references/plan-contract.md`; `references/step-queue-spawn.md` |
| 5 | Before the spawn: `repo-analyst` and `architect`; also `database` when the step or PLAN cites persistence. Contract, order, or acceptance drift: stop with `plan_stale` and return to `sdd-plan`. Do not rewrite the graph here. Show `execution-display.md` around the spawn. Then spawn exactly one step child | `references/execution-display.md`; `references/execution-modes.md`; `references/develop-modes.md`; `references/step-queue-spawn.md`; `references/anti-bypass.md` |
| 5.5 | Post-implement verifier when `verify_mode: true` | `references/step-verifier.md` |
| 6 | Safe parallelism (only when mode=`parallel`; distinct SESSION files) | `references/execution-modes.md`; `references/parallelism.md` |
| 7 | Stop conditions | `references/continuity-handoff.md` § Stop |
| 8 | Update CONTINUITY | `references/continuity-handoff.md` |
| 9 | Step N refresh-light after app file changes | `references/continuity-handoff.md` § Step N; `references/preconditions.md` |
| 10 | Scope close, in this order: `code-review`, `run-tests`, `security`, then ask `/commit`, then ask `/push` separately | `references/continuity-handoff.md` § Handoff |

**Anti-bypass:** `references/anti-bypass.md`. **Must not (full):** `references/must-not.md`.
