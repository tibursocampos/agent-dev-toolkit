# sdd-spec — command playbook

**Load after Step -1 gates.** Ordered step discovery without dumping `SKILL.md` Process (REQ-006 / CA3). Load **one** section file per step (`SKILL-REFERENCE-RETRIEVAL.md`).

| Step | Action | Lazy section / contract |
|------|--------|-------------------------|
| -1b | Caveman Lite when active | `CAVEMAN.md` |
| -1 | Pipeline + STORAGE; `invocation_context`; load provenance | `PIPELINE.md`, `STORAGE.md`, `INVOCATION-CONTEXTS.md`, `CONTRACT-PROVENANCE.md` |
| 0 | Workspace; detect stack; resolve NNN / US01 default | `STORAGE.md` |
| 1 | Requirements (Prior ≤3 gaps; selective retrieval; required siblings STOP) | `SELECTIVE-RETRIEVAL.md`; `PIPELINE.md` § Prior |
| 2–5 | Confirm repo, explore, clarify ≤5, technical analysis | — |
| 5.5 | Challenge vagueness + **product depth** + REQ (`agreed` vs `invented`); no how/code | `references/challenge-vagueness.md`, `references/req-tracking.md`; lazy `feature-altitude.md`, `invest-and-story-quality.md`, `gherkin-budget.md`, `clarify-depth.md`, `product-evidence-lite.md`; `anti-task-shatter.md` only if titles task-shaped; `CONTRACT-PROVENANCE.md` |
| 6 | Context checkpoint | `context-management.mdc` |
| 6.75 | Confirm before write (**sim**) | `PIPELINE.md` |
| 7 | Write PRD (Agent + sim only); portable paths | `references/template-usage.md`, `references/filename-numbering.md`, `references/storage-gitignore.md` |
| 7.5 | Structural validate (`validate-prd`; CHANGE when brownfield) | `references/validate-prd.md`, `references/validate-change.md` |

Quality: `references/quality-checklist.md`. Language: `references/product-docs-language.md`, `references/english-override.md`.
