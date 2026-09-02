# sdd-develop — command playbook

**Load after Step -1 gates.** Ordered step discovery without dumping `SKILL.md` Process (REQ-006 / CA3). One PLAN step per session. Load **one** section file per step (`SKILL-REFERENCE-RETRIEVAL.md`).

| Step | Action | Lazy section / contract |
|------|--------|-------------------------|
| -1b | Caveman Full when active | `CAVEMAN.md` |
| -1 | Pipeline + STORAGE; resolve `invocation_context`; honor provenance | `PIPELINE.md`, `STORAGE.md`, `INVOCATION-CONTEXTS.md`, `CONTRACT-PROVENANCE.md` |
| 0 | Resolve canonical PLAN; load PLAN-scoped develop SESSION | `SESSION.md`; `SKILL.md` § Workspace |
| 1 | Validate step (deps Completed; Aceite REQ/CA); ask proceed | PLAN step block |
| 2 | Feature branch / git prep | `references/git-checklist.md` |
| 3–4 | Analyze + implement; targeted tests; child receipt | `references/code-analysis.md`, `references/stack-pointers.md` |
| 4b | Evidence-or-zero when level ≥ cheap | `references/evidence-or-zero.md`; `EVD-STATE-CONTRACT.md` |
| 4c | Living loop + TRACE at wave close | `references/living-loop-trace.md`; `TRACE-ARCHIVE-CONTRACT.md` |
| 5 | Offer `/commit` (do not auto-commit) | — |
| 6 | Update PLAN in place; checkpoint | `references/plan-update.md` |
| 7 | Session report; handoff next step | `references/session-report.md` |

Before Completed: `references/quality-self-check.md`. Forbidden: `references/forbidden.md`. Optional: `references/optional-flows.md`.
