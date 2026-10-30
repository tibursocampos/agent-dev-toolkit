# refine-story — command playbook

**Load after Step -1 gates.** Ordered step discovery without dumping `SKILL.md` Process. Load **one** section file per step (`SKILL-REFERENCE-RETRIEVAL.md`).

| Step | Action | Lazy section / contract |
|------|--------|-------------------------|
| -1b | Caveman Lite when active | `CAVEMAN.md` |
| 0 | Workspace; `invocation_context`; check `features/**/PRD/` | `INVOCATION-CONTEXTS.md`; `STORAGE.md` |
| 0.5 | Resolve refine mode (`feature` \| `tech` \| `split`); **STOP** if unset/invalid | Trigger prompt in `SKILL.md`; `references/mode-isolation.md`; then **only** `references/<mode>.md` |
| 0.6 | Open skeleton **interaction envelope** (`mode`, `invocation_context`, `status`) | `references/interaction-envelope.md` |
| 1–3 | Collect + generate (mode playbook); append Q&A entries when clarifying | Chosen mode file; **one** `_shared/backlog-item-types/` file; `references/qa-history.md`; `SELECTIVE-RETRIEVAL.md`; `references/boundary.md` |
| 4 | Quality scorecard (Product depth + AC budget) | `references/scorecard-rubric.md`, `references/scorecard-template.md`; lazy `gherkin-budget.md`, `invest-and-story-quality.md`, `product-evidence-lite.md` |
| 4a | Requirement review before handoff: `requirement-review --feature`, then `--tech` when the story touches a repository. Pointer only; statuses feed step 4b | `{{TOOLKIT_ROOT}}/skills/requirement-review/SKILL.md` |
| 4b | Refresh envelope `status` per the READY rule; sync `qa_history_ref` | `readiness-severity.md` (consume); `interaction-envelope.md`; `qa-history.md` |
| 5 | Validation (chat-only) | `references/guardrails.md` |
| 6 | Optional persistence (file-based only; include Q&A history) | `references/persistence.md`; `references/qa-history.md`; `references/exclusions.md` |
| 7 | Handoff (split / sdd-spec / O1) — **portable paths only** | `references/split-handoff.md`; `references/boundary.md`; `references/exclusions.md` |

**Mode isolation (REQ-004 / CA2):** after 0.5, load **exactly one** of `references/feature.md` | `references/tech.md` | `references/split.md`. Never preload the other two. Matrix: `mode-isolation.md`.

**Envelopes + Q&A (REQ-005):** emit/refresh envelope; persist/consult Q&A history under `REFINE/qa-history.md` (or documented fallback).

**READY dual-plane (REQ-006):** consume `readiness-severity.md` — do **not** rewrite taxonomy or reopen Assert PS1. READY ≠ `step_confirmed`. Handoffs use portable paths only (RNF-002).

**Requirement challenge (step 4a):** feature and tech challenge live in `requirement-review`. This skill calls it and reads its status; it does not copy its playbooks. Never a monolithic `feature-refinement.md`.

**Must not:** see `SKILL.md` § Must not + `references/exclusions.md` (no Azure WI / external trackers).
