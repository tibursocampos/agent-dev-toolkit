## Scorecard template

### Scorecard output format

```markdown
---

## Quality scorecard

| Criterion | Score | Max | Note |
|-----------|-------|-----|------|
| Objective | [x] | 12 | [specific note] |
| Acceptance criteria (BDD) | [x] | 20 | [happy / rule / failure budget status] |
| Product depth | [x] | 10 | [Valuable + AC budget + Who/Job/Outcome; Evidence omit OK] |
| Story scope | [x] | 10 | [specific note] |
| Implementation steps | [x] | 13 | [specific note] |
| No vague language | [x] | 5 | [specific note] |
| [type-specific 1] | [x] | [max] | [specific note] |
| [type-specific 2] | [x] | [max] | [specific note] |
| [type-specific 3] | [x] | [max] | [specific note] |
| [type-specific 4] | [x] | [max] | [specific note] |

### Total: [sum] / 100

### Strengths
- [specific]

### Improvements
- **[Criterion]**: [what is missing and how to fix]

---
```

Rules: notes must be specific (not "OK"); improvements name exact gaps; incomplete user input reflected honestly.

**AC budget:** Acceptance criteria notes must state whether **happy**, **rule/edge**, and **failure** slots are present with observable Then (`gherkin-budget.md`). Cap Product depth at **6** if any slot is missing.

**Persona / JTBD:** Optional for User Story (`persona-context.md`). Scorecard must **not** penalize absence of persona, JTBD, Who / Job / Outcome, or Product intent on **Bug** or **Technical Story** (use `n/a`). On User Story, missing persona is not a defect when Objective states beneficiary and value — but Who/Job/Outcome (or equivalent) is required for full Product depth.

**Evidence:** Do **not** force inventing Evidence (`product-evidence-lite.md` — omit > fabricate).

When persisting as `STORY.md`, copy a short scorecard summary into the template `Scorecard (resumo)` table. Map **Product depth** from the Product depth criterion (/10 → 1–5) per `scorecard-rubric.md`. Map other rows from overall /100 bands when a dedicated criterion score is unavailable: 80+ = 5, 60–79 = 4, 40–59 = 3, else ≤2.

---
