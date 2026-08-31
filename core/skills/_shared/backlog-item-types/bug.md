# Backlog item type: Bug

Templates and writing rules for `refine-story`. Output is **markdown in chat** (optional save under `docs/backlog/` in the target repo). No external tracker API.

**Persona / JTBD:** Not required. Do not add Who / Job / Outcome for bugs. Scorecard must not penalize absence of persona (`persona-context.md`).

---

## Required sections

| Section | Purpose |
|---------|---------|
| Objective (implicit in Error) | What is wrong and why it matters |
| Error | Incorrect behavior, reproduction, evidence |
| Expected Result | Correct behavior after fix, BDD verification |
| Implementation steps | Suggested fix as baby steps (under Error or separate) |

---

## Output template

```markdown
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🐛 BUG - [title or slug]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## Error

**🔗 Dependencies:** (omit section if none)
- [dependency id or link]

**Incorrect behavior:**
[Precise description of what goes wrong]

**Context:**
[Where it occurs, when introduced, affected flow]

**🗂️ Repositories / areas:**
- [repo or service 1]
- [repo or service 2]

**Primary area:** (optional — repo, service, or module where fix is expected; omit if unknown)

**Affected files or components:** (optional hints — prefer behavior in steps)
- [path or component]

**Steps to reproduce:**
1. [Initial state]
2. [Action]
3. [Where failure appears]

**Evidence:**
[HTTP status, log excerpt, error message, observable behavior]

**Frequency and impact:**
[Always / intermittent - who or what is affected]

### 🧩 Suggested fix (steps)

**Step 1 - [Behavior-oriented action title]**
[What to change and why — verifiable outcome for this step]
- Primary area: [repo / module — optional if already at story level]
- Touch: [path or component — optional hint]
- Depends on: [none / Step N]

**Step 2 - [Behavior-oriented action title]**
[What to do]
- Touch: [path — optional]
- Depends on: [Step 1]

---

## Expected Result

**Expected behavior:**
[Positive description of correct behavior after fix]

**Verification criteria:**

🎬 Scenario 1 - [Primary fix verification]
**Given** [same conditions that reproduce the bug]
**When** [same action that triggered the error]
**Then** [correct system behavior]
**And** [no error / correct payload / consistent data]

🎬 Scenario 2 - [Non-regression]
**Given** [adjacent normal usage context]
**When** [related flows run]
**Then** [existing behavior remains correct]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Collection questions

When input is thin, ask:

```
🐛 Bug - need more detail

1. What is going wrong? (objective description)
2. How do you reproduce it? (steps, environment, sample data)
3. What should happen instead?
4. Impact? (frequency, users or processes affected)
5. Where to fix? (file, method, component - optional)
6. Severity? (optional: Critical / High / Medium / Low)
```

---

## Writing guidelines

**Dependencies:** Include only if the dev names blocking items; format `- [id or short label]`; omit the section if none.

**Error:** Describe what **happens**, not vague "does not work". Reproduction steps must be specific enough for another dev without extra context. Include concrete evidence.

**Primary area:** Optional at story level (repo/service/module). Do not replace objective or reproduction context.

**Suggested fix steps:** Same structure as Technical Story steps — one responsibility per step; **titles name behavior**, not file/class only (`story-sizing.md`); optional `Touch:` hint; explicit dependencies.

**Expected Result:** State positive correct behavior, not only absence of error. BDD scenarios reuse reproduction conditions. Include non-regression for adjacent flows when relevant.

**Severity:** Optional label in markdown only - do not assume a corporate enum.

---

## Reference example (generic)

**Incorrect behavior:** API returns HTTP 500 when creating an order with an optional field empty; response body has no error code.

**Context:** Regression after validation refactor in `OrderController`.

**Steps to reproduce:** POST `/api/orders` with `{ "customerId": "valid-guid", "notes": "" }` -> 500.

**Step 1 - Validate empty optional field in create-order command** - Application - depends on: none. Touch: `OrderValidator` (optional).

**Expected:** HTTP 400 with validation message when `notes` is invalid; HTTP 201 when valid.
