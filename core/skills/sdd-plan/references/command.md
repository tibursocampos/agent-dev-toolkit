# sdd-plan — command playbook

**Load after Step -1 gates.** Ordered step discovery without dumping `SKILL.md` Process (REQ-006 / CA3). Load **one** section file per step (`SKILL-REFERENCE-RETRIEVAL.md`).

| Step | Action | Lazy section / contract |
|------|--------|-------------------------|
| -1b | Caveman Lite when active | `CAVEMAN.md` |
| -1 | Pipeline + STORAGE; `invocation_context` | `PIPELINE.md`, `STORAGE.md`, `INVOCATION-CONTEXTS.md` |
| 0 | Workspace; stack; classic feature root | `STORAGE.md` |
| 1 | Resolve PRD (canonical path only) | `references/filename-numbering.md` |
| 2–4 | Explore the repo; call `split-story-checklist` with `source=prd`; copy step ids from `REFINE/tasks.md`; two self-reviews before preview | `references/baby-step-sizing.md`, `references/self-review.md`, `references/challenge-vagueness.md`, `references/plan-magro.md`; `LIVE-STAGE-TABLE.md` § sdd-plan |
| 5 | Context checkpoint | `context-management.mdc` |
| 5.5 | PLAN storage path | `references/storage-gitignore.md` |
| 5.75 | Confirm before write (**sim**) | `PIPELINE.md` |
| 6 | Write PLAN (Agent + sim; magro; Execution policy; Mapa REQ) | `references/template-usage.md`, `references/plan-magro.md` |
| 6.5 | Structural validate (`validate-plan`) | `references/validate-plan.md` |
| 7 | Validate with user; handoff develop | `references/quality-checklist.md`, `references/status-legend.md` |

Selective retrieval: `references/selective-retrieval.md`. Product docs language: `references/product-docs-language.md`.
