## Scorecard rubric

Score immediately after generating the markdown. Maximum **100** points. Portable backlog refinement style (no external work-item fields).

### Universal criteria (all types)

| Criterion | Max | Scoring guide |
|-----------|-----|----------------|
| Objective | 15 | 15: affirmative, ≤3 sentences, correct perspective, specific / 8: correct but long or generic / 3: vague or wrong perspective / 0: missing |
| Acceptance criteria (BDD) | 25 | 25: all Given/When/Then, covers happy path + error + edge / 15: BDD present but incomplete / 8: no BDD or intent language / 0: missing |
| Story scope | 10 | 10: one verifiable user/technical outcome (ideally one PR); objective and steps name behavior not files / 5: mostly outcome-oriented but some file/layer fragmentation / 0: file-per-step, layer-per-story, or objective is a file list |
| Implementation steps | 15 | 15: baby steps, infinitive verbs, behavior titles (not file/class only), layer order, explicit deps / 9: steps ok but weak granularity, deps, or file-only titles / 4: generic steps / 0: missing |
| No vague language | 5 | 5: none / 2: 1-2 vague phrases / 0: multiple |

**Story scope contract:** `skills/_shared/backlog-item-types/story-sizing.md`. Penalize step titles that are **only** a file path, class name, or layer label (e.g. "`OrderController.cs`", "Domain layer") — titles must state the behavior or change.

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
