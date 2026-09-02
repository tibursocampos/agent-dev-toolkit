# refine-story — command playbook

**Load after Step -1 gates.** Ordered step discovery without dumping `SKILL.md` Process. Load **one** section file per step (`SKILL-REFERENCE-RETRIEVAL.md`).

| Step | Action | Lazy section / contract |
|------|--------|-------------------------|
| -1b | Caveman Lite when active | `CAVEMAN.md` |
| 0 | Workspace; `invocation_context`; check `features/**/PRD/` | `INVOCATION-CONTEXTS.md`; `STORAGE.md` |
| 0.5 | Resolve refine mode (`feature` \| `tech` \| `split`); **STOP** if unset/invalid | Trigger prompt in `SKILL.md`; then **only** `references/<mode>.md` |
| 1–3 | Collect + generate (mode playbook) | Chosen mode file; **one** `_shared/backlog-item-types/` file; `SELECTIVE-RETRIEVAL.md`; `references/boundary.md` |
| 4 | Quality scorecard (Product depth + AC budget) | `references/scorecard-rubric.md`, `references/scorecard-template.md`; lazy `gherkin-budget.md`, `invest-and-story-quality.md`, `product-evidence-lite.md` |
| 5 | Validation (chat-only) | `references/guardrails.md` |
| 6 | Optional persistence (file-based only) | `references/persistence.md`; `references/exclusions.md` |
| 7 | Handoff (split / sdd-spec / O1) | `references/split-handoff.md`; `references/exclusions.md` |

**Mode isolation (REQ-003 / CA3):** after 0.5, load **exactly one** of `references/feature.md` | `references/tech.md` | `references/split.md`. Never preload the other two.

**Must not:** see `SKILL.md` § Must not + `references/exclusions.md` (no Azure WI / external trackers — REQ-004 / CA4).
