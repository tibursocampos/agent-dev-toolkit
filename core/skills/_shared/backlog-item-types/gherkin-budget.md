# Gherkin AC budget

Minimum acceptance-criteria budget for stories that claim Product depth. Used by O1 STORY synthesis, `refine-story` scorecard, and future Asserts.

External ideas (paraphrase only): Given/When/Then scenarios with observable outcomes — curated link in `docs/CREDITS.md`; do not dump vendor tutorial corpora.

---

## Minimum budget (US / behavioral TS)

At least **three** scenarios, each with an **observable Then**:

| Slot | Intent | Then must |
|------|--------|-----------|
| **Happy** | Main success path | Show successful observable result |
| **Rule / edge** | Business rule or boundary | Show correct constrained behavior |
| **Failure** | Error, denial, or invalid input | Show failure/recovery observable to the actor |

Fewer than three, or scenarios without Then, fail AC budget (PRD TE03 / CA3).

---

## Writing rules

- Prefer business language over implementation details in business AC.
- Technical AC checklists may accompany BDD; they do **not** replace the three-scenario budget when Product depth is required.
- One Gherkin stub alone is **not** enough.
- Do not invent PII or production secrets inside examples (`product-evidence-lite.md`).

---

## Mapping to scorecard

| Check | Pass |
|-------|------|
| Happy present | Yes |
| Rule/edge present | Yes |
| Failure present | Yes |
| Each Then observable | Yes |
| Product depth note (1–5) | Filled on STORY summary when refine/analyze requires it |

---

## Relationship

| Ref | Role |
|-----|------|
| `invest-and-story-quality.md` | Testable letter of INVEST |
| `clarify-depth.md` | Questions that unlock missing scenarios |
| `product-evidence-lite.md` | Evidence fields stay omit-safe |
