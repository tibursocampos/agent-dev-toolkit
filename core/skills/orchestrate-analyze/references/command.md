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
| 7 | Allocate NNN-slug; scaffold feature tree | `references/story-synthesis.md` |
| 8 | Spawn Task specialists (SPAWN; omit model) | `references/spawn-map.md`; `SPAWN.md` |
| 8b | Architecture confirm gate | `references/arch-confirm.md` |
| 9 | Synthesize FEATURE / CONTINUITY / STORY; run product artifact quality gates (FEATURE depth TE01, promotion TE02, cap ≤4) | `references/story-synthesis.md`; lazy `anti-task-shatter.md` / `feature-altitude.md` |
| 10 | Human backlog approval (**sim**) — only if gates passed | `references/process-common.md` § Backlog approval |
| 11 | Approve → CONTINUITY + O2 handoff | `references/boundaries-handoff.md` |
| 12 | Context pressure / resume | `references/process-common.md` § Context pressure |

**Must not (full):** `references/must-not.md`. Handoff strings: `references/boundaries-handoff.md`.
