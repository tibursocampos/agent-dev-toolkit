# Backlog item type: User Story

Templates and writing rules for `refine-story`. Output is **markdown in chat** (optional save under `docs/backlog/` in the target repo). No external tracker API.

---

## Required sections

| Section | Purpose |
|---------|---------|
| Objective | What is delivered and the value for users or the business |
| Context | Current vs expected flow, scope |
| Repositories | Affected codebases or services |
| Implementation steps | Baby steps for delivery |
| Acceptance criteria | Business-verifiable BDD |
| Technical acceptance criteria | Implementation-verifiable checklist (not BDD) |

## Optional sections

| Section | Purpose |
|---------|---------|
| Who / Job / Outcome | Persona, JTBD, problem, evidence — see `persona-context.md`. Omit when Objective already states beneficiary and value. |

---

## Output template

```markdown
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
👤 USER STORY - [title or slug]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

### 🎯 Objective
[What must be delivered and the value generated - user or business perspective.]

---

### Who / Job / Outcome (optional)
- **Who:** [role / segment]
- **Job:** [JTBD in one sentence]
- **Outcome:** [progress the user measures]
- **Problem:** [optional — friction today]
- **Evidence:** [optional — quote, metric, ticket]

Guideline: `skills/_shared/backlog-item-types/persona-context.md`

### 🔗 Dependencies (omit if none)
- [dependency id or link]

### 🚀 Context
[2-3 short paragraphs: current situation -> need -> proposed solution and scope]

### 🗂️ Repositories / areas
- [repo or service 1]
- [repo or service 2]

### Current flow
[How the process works today]

### Expected flow
[How it should work after delivery]

### 🧩 Steps

**Step 1 - [Action title]**
[What to do in this step]
- Layer: [Domain / Application / Infrastructure / API / Pipeline / UI]
- Depends on: [none / Step N]

**Step 2 - [Action title]**
[What to do]
- Layer: [...]
- Depends on: [Step 1]

---

### 🕵️ Acceptance criteria (business)

🎬 Scenario 1 - [Main business flow]
**Given** [user or system context]
**When** [action]
**Then** [business outcome]
**And** [additional business condition]

🎬 Scenario 2 - [Rule or alternate flow]
**Given** [...]
**When** [...]
**Then** [...]

🎬 Scenario 3 - [Failure or exception for the user]
**Given** [...]
**When** [...]
**Then** [...]

---

### 🔧 Technical acceptance criteria

- [ ] [Verifiable technical item - API contract, validation, component behavior]
- [ ] [Verifiable technical item]
- [ ] [Verifiable technical item]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Collection questions

When input is thin, ask:

```
📝 User Story - need more detail

1. What must be delivered? (free description)
2. How does it work today?
3. How should it work after the change?
4. Who uses it? (end user, operator, external system)
5. Business rules, exceptions, or extra context (optional)
```

---

## Writing guidelines

**Objective:** Beneficiary perspective - not "the system must". Include value (e.g. removes manual step).

**Who / Job / Outcome:** Optional. Load `persona-context.md` when who/job/outcome clarifies value beyond Objective. Do not invent named fictional personas. Scorecard does not require this block.

**Dependencies:** Omit section if none.


**Acceptance criteria (business):** No HTTP codes, class names, or DB details. Cover main flow, business rule, and user-visible failure. Use **Given / When / Then / And**.

**Technical acceptance criteria:** Markdown checkboxes only - **no BDD** in this section. Technical language allowed (status codes, endpoints, tables, queues). Do not duplicate business criteria.

**Steps:** Infinitive verbs; layer order Domain -> Application -> Infrastructure -> API -> Tests when applicable; explicit dependencies; mark parallel steps when independent.

---

## Reference example (generic)

**Objective:** Allow operators to export archived records by date range so they no longer query the primary database manually.

**Current flow:** Export is a manual SQL script run by ops.

**Expected flow:** Authenticated UI action generates CSV for a validated date range with audit log.

**Step 1 - Add export query and handler** - Application - depends on: none.

**Business AC:** Given an operator with export permission, When they request a valid range, Then a CSV download starts within 30 seconds.

**Technical AC:** - [ ] Endpoint returns 400 for end date before start date.
