# Persona / JTBD context (optional)

Optional product-intent sections for backlog refinement. English guideline. Lazy-load from `refine-story` and O1 story synthesis only — do **not** load by default for every skill.

**Applicability:**

| Item type | Persona / JTBD |
|-----------|----------------|
| User Story | **Optional** — include when who/job/outcome clarifies value |
| Technical Story | **Not required** — out of scope for pure technical work |
| Bug | **Not required** — focus on repro, evidence, expected fix |

Scorecard must **not** penalize absence of persona on Bug or Technical Story. On User Story, absence is allowed; do not treat missing persona as a score defect unless the item is otherwise vague about the beneficiary.

---

## Optional sections

| Section | Purpose |
|---------|---------|
| Persona | Who benefits (role, context) — not a named BMAD-style character |
| JTBD | Job to be done: situation → motivation → expected progress |
| Problem | Pain or friction today (why this story now) |
| Evidence | Light signal only (user quote, metric, incident) — omit if none |

Do **not** invent fictional named personas (e.g. "John the PM"). Prefer roles and jobs.

---

## Compact block (User Story)

When useful, add under Context (or after Objective):

```markdown
### Who / Job / Outcome (optional)
- **Who:** [role / segment]
- **Job:** [JTBD in one sentence]
- **Outcome:** [progress the user measures]
- **Problem:** [optional — friction today]
- **Evidence:** [optional — quote, metric, ticket]
```

Omit the entire block when the Objective already states beneficiary and value clearly.

---

## Writing guidelines

**Persona:** Role + situation (e.g. "ops analyst exporting archives weekly"). No biography or psychographics.

**JTBD:** One sentence: When [situation], I want to [motivation], so I can [outcome].

**Problem:** Distinct from Objective — current pain, not the delivery statement.

**Evidence:** Optional; one concrete signal beats a paragraph of speculation. Skip rather than fabricate.

**Technical Story / Bug:** Prefer technical motivation, repro, and impact. Do not force Who / Job / Outcome.

---

## Relationship

| Artifact | Role |
|----------|------|
| `user-story.md` | May include Who / Job / Outcome pointing here |
| `technical-story.md` | Notes persona out of scope for pure TS |
| `bug.md` | No persona sections |
| `FEATURE.md` | Optional **Product intent** near story Rationale |
| `refine-story` | Lazy-load this file when refining a User Story that needs product context |
| `orchestrate-analyze` | Lazy-load at FEATURE synthesis for US **Product intent** only (TS/Bug → `n/a`) |
