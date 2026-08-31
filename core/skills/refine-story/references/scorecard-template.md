## Scorecard template

### Scorecard output format

```markdown
---

## Quality scorecard

| Criterion | Score | Max | Note |
|-----------|-------|-----|------|
| Objective | [x] | 15 | [specific note] |
| Acceptance criteria (BDD) | [x] | 25 | [specific note] |
| Story scope | [x] | 10 | [specific note] |
| Implementation steps | [x] | 15 | [specific note] |
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

**Persona / JTBD:** Optional for User Story (`persona-context.md`). Scorecard must **not** penalize absence of persona, JTBD, Who / Job / Outcome, or Product intent on **Bug** or **Technical Story**. On User Story, missing persona is not a defect when Objective states beneficiary and value.

When persisting as `STORY.md`, copy a short scorecard summary into the template `Scorecard (resumo)` table (1-5 scale mapped from /100 bands: 80+ = 5, 60-79 = 4, 40-59 = 3, else ≤2).

---
