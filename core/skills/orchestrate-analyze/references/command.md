# orchestrate-analyze — command playbook

**Load after Step -1 gates.** Ordered step discovery without dumping `SKILL.md` Process (REQ-006 / CA3). Load **one** section file per step (`SKILL-REFERENCE-RETRIEVAL.md`).

| Step | Action | Lazy section / contract |
|------|--------|-------------------------|
| -1b | Caveman Lite when active | `references/process-common.md` § Caveman |
| 1 | Gate check; load PIPELINE + SESSION; STOP if unchecked | `PIPELINE.md`, `SESSION.md` |
| 1b | Resolve `invocation_context` (default `orchestrated`) | `INVOCATION-CONTEXTS.md` |
| 2 | Resolve storage / bank roots; path sanitize | `references/process-common.md` § Resolve storage; `STORAGE.md` |
| 3 | Intent classification (triage entry) | `references/intent-classification.md` |
| 4 | Step 0 Memory Bank Gate (`auto`) | `references/memory-bank-gate.md`; `MEMORY-BANK.md` |
| 5 | Collect description and triage (`needs_*`) | `references/triage.md`; `ROSTER.md` |
| 6 | Trivial shortcut (optional exit) | `references/triage.md` § Trivial |
| 7 | Allocate NNN-slug; scaffold `FEATURE.md` and `CONTINUITY.md` only (no story folders) | `references/story-synthesis.md` |
| 8 | Spawn Task specialists (SPAWN; omit model). Return notes to the parent. Do not create story folders until step 9 | `references/spawn-map.md`; `SPAWN.md` |
| 8b | Architecture confirm gate. Return the ARCH draft to the parent until step 9 | `references/arch-confirm.md` |
| 8c | Feature research on `FEATURE.md` only. Show `LIVE-STAGE-TABLE.md`. If `open_question`, stop. Do not run step 9 | `{{TOOLKIT_ROOT}}/skills/refine-story/references/feature-research.md`; `readiness-severity.md` § Open-question gate; `LIVE-STAGE-TABLE.md` |
| 9 | Synthesize story folders only when FEATURE has no open question. Then FEATURE / CONTINUITY / STORY and product artifact quality gates (FEATURE depth TE01, promotion TE02, cap ≤4) | `references/story-synthesis.md`; lazy `anti-task-shatter.md` / `feature-altitude.md` |
| 10 | Human backlog approval (**sim**) — only if gates passed | `references/process-common.md` § Backlog approval |
| 11 | Approve → CONTINUITY + O2 handoff | `references/boundaries-handoff.md` |
| 12 | Durable progress handoff | `references/process-common.md` § Durable progress handoff |

**Must not (full):** `references/must-not.md`. Handoff strings: `references/boundaries-handoff.md`.

## Cumulative O1 checkpoint

At O1 start, render the cumulative O1/O2 checkpoint from `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/LIVE-STAGE-TABLE.md`. Refresh it after each material evidence pass or decision, before/after an open-question or architecture/backlog approval gate, when blocked, and at handoff/close. The checkpoint shows current process, completed evidence, pending analysis/artifacts, decisions/questions, blockers and next action; keep prior relevant findings across redraws. Derive facts from canonical feature/story artifacts and confirmed conversation decisions. The checkpoint and stage table are chat-only; do not add a second persisted ledger to FEATURE or CONTINUITY. At O1 step 8c, render both the feature-research stage table and the cumulative checkpoint.
