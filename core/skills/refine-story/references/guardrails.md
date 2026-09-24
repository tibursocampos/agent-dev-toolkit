## Guardrails (before marking output final)

**Universal:**

- [ ] No empty or placeholder sections
- [ ] No vague phrases: "works correctly", "as expected", "properly"
- [ ] BDD uses **Given / When / Then / And**
- [ ] AC budget: at least **happy + rule/edge + failure**, each with observable Then (`gherkin-budget.md`)
- [ ] Scorecard includes **Product depth**; Evidence omit is OK (`product-evidence-lite.md`)
- [ ] No unit-test scenarios in acceptance criteria
- [ ] No "verify environment variable X" as acceptance criteria
- [ ] Section icons/headings match the type template when saving chat form
- [ ] Titles/objectives outcome-shaped — not verb+file/class/script (`anti-task-shatter.md`)

**Technical Story / User Story:**

- [ ] Steps ordered by layer when applicable
- [ ] Step titles name **behavior**, not file/class/layer only (`story-sizing.md`)
- [ ] Story represents one verifiable outcome (not a file or layer checklist)
- [ ] Dependencies section omitted when none (not "N/A" filler)
- [ ] Each step has explicit `Depends on:` for topological breakdown

**User Story:**

- [ ] Business AC without implementation jargon
- [ ] Technical AC as checkboxes, not BDD

**Bug:**

- [ ] Reproduction steps are actionable
- [ ] Expected result describes positive behavior

If guardrails fail, ask for missing detail - do not publish incomplete docs.

**Clarification readiness (REQ-004–006):** open questions carry **B** \| **I** \| **MINOR** (`clarify-depth.md` / `readiness-severity.md`). Any open **B**/**I** → status `NEEDS_CLARIFICATION`; do not hand off as ready-for-PRD. Presence ≠ READY (**RN02**). Dual plane: readiness ≠ `step_confirmed` / PLAN Complete (REQ-006).

**Mode isolation (REQ-004):** only the active mode playbook loaded; envelope `mode` matches (`mode-isolation.md`).

**Envelope + Q&A (REQ-005):** interaction envelope refreshed; Q&A history path portable and consultable when persisted (`interaction-envelope.md`, `qa-history.md`).

**Handoffs:** portable paths only — no OS absolute / InstallRoot embeds (RNF-002).

**Selective retrieval:** do not dump entire `memory-bank/` or paste full PRD into refine chat/handoffs (`SELECTIVE-RETRIEVAL.md` / `SR-NO-FULL-DUMP`).

---
