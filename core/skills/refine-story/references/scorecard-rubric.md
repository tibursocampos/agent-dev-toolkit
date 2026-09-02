## Scorecard rubric

Score immediately after generating the markdown. Maximum **100** points. Portable backlog refinement style (no external work-item fields).

**Norms (lazy-load at score time):** `gherkin-budget.md`, `invest-and-story-quality.md`, `product-evidence-lite.md`, `story-sizing.md`. Do not preload the full backlog-item-types folder.

### Universal criteria (all types) — 70 points

| Criterion | Max | Scoring guide |
|-----------|-----|----------------|
| Objective | 12 | 12: affirmative, ≤3 sentences, correct perspective, specific / 7: correct but long or generic / 3: vague or wrong perspective / 0: missing |
| Acceptance criteria (BDD) | 20 | 20: Given/When/Then covering **happy + rule/edge + failure**, each with an **observable Then** (`gherkin-budget.md`) / 12: BDD present but missing one budget slot / 6: single stub or Then not observable / 0: missing |
| Product depth | 10 | 10: Valuable clear + AC budget met + Who/Job/Outcome when US (`n/a` OK for TS/Bug); honest Evidence omission is **not** a fail (`product-evidence-lite.md`) / 6: Valuable weak or AC budget partial / 3: thin product signal / 0: task-shaped or no Valuable |
| Story scope | 10 | 10: one verifiable user/technical outcome (ideally one PR); objective and steps name behavior not files / 5: mostly outcome-oriented but some file/layer fragmentation / 0: file-per-step, layer-per-story, or objective is a file list |
| Implementation steps | 13 | 13: baby steps, infinitive verbs, behavior titles (not file/class only), layer order, explicit deps / 8: steps ok but weak granularity, deps, or file-only titles / 4: generic steps / 0: missing |
| No vague language | 5 | 5: none / 2: 1-2 vague phrases / 0: multiple |

**Story scope contract:** `skills/_shared/backlog-item-types/story-sizing.md`. Penalize step titles that are **only** a file path, class name, or layer label (e.g. "`OrderController.cs`", "Domain layer") — titles must state the behavior or change.

**Product depth contract:** Valuable (`invest-and-story-quality.md`) + AC budget (`gherkin-budget.md`) + Who/Job/Outcome when US. Do **not** deduct for omitted Evidence alone.

### Type-specific criteria (30 points total)

**Technical Story:**

| Criterion | Max |
|-----------|-----|
| Technical context (problem -> solution -> scope) | 10 |
| Repositories / areas listed | 5 |
| Technical specificity (types, endpoints, events when relevant) | 10 |
| Dependencies declared or N/A justified | 5 |

**User Story:**

| Criterion | Max |
|-----------|-----|
| Context + current vs expected flow | 10 |
| Repositories / areas listed | 5 |
| Business AC vs technical AC separated | 10 |
| Dependencies declared or N/A justified | 5 |

**Bug:**

| Criterion | Max |
|-----------|-----|
| Repro steps + evidence | 10 |
| Frequency and impact | 5 |
| Suggested fix steps with files and deps | 10 |
| Non-regression BDD scenario | 5 |

### Map /100 and Product depth → STORY 1–5

**Overall total** (for chat summary / Clareza–Testabilidade composites when needed):

| Band (/100) | STORY 1–5 |
|-------------|-----------|
| 80–100 | 5 |
| 60–79 | 4 |
| 40–59 | 3 |
| 1–39 | 2 |
| 0 | leave blank or 0 |

**Product depth criterion** (max 10) → STORY **Product depth** row:

| Score (/10) | STORY 1–5 |
|-------------|-----------|
| 9–10 | 5 |
| 7–8 | 4 |
| 5–6 | 3 |
| 3–4 | 2 |
| 1–2 | 1 |
| 0 | 0 / blank |

Minimum AC budget (happy + rule/edge + failure with observable Then) must hold before Product depth can score above **6**.
