# Backlog item type: Technical Story

Templates and writing rules for `refine-story`. Output is **markdown in chat** (optional save under `docs/backlog/` in the target repo). No external tracker API.

---

## Required sections

| Section | Purpose |
|---------|---------|
| Objective | What will be built and the technical value |
| Context | Problem, scope, technical motivation |
| Repositories | Affected codebases or services |
| Implementation steps | Baby steps in layer order |
| Acceptance criteria | Technical BDD (verifiable facts) |

---

## Output template

```markdown
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📐 TECHNICAL STORY - [title or slug]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

### 🎯 Objective
[Clear statement of what will be built and the technical value - no code blocks.]

---

### 🔗 Dependencies (omit if none)
- [dependency id or link]

### 🚀 Context
[2-3 short paragraphs: current state -> problem -> proposed solution and scope]

### 🗂️ Repositories / areas
- [repo or service 1]
- [repo or service 2]

---

### 🧩 Steps

**Step 1 - [Action title]**
[What to do in this step]
- Layer: [Domain / Application / Infrastructure / API / Tests]
- Depends on: [none / Step N]

**Step 2 - [Action title]**
[What to do]
- Layer: [...]
- Depends on: [Step 1]

---

### 🕵️ Acceptance criteria

🎬 Scenario 1 - [Happy path]
**Given** [technical initial context]
**When** [action]
**Then** [observable result]
**And** [extra condition if needed]

🎬 Scenario 2 - [Validation / invalid input]
**Given** [invalid or incomplete data]
**When** [action]
**Then** [descriptive error, no side effects]

🎬 Scenario 3 - [Error or edge case]
**Given** [failure context]
**When** [action]
**Then** [correct handling]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Collection questions

When input is thin, ask:

```
📝 Technical Story - need more detail

1. What needs to be built? (free description)
2. Why is this change needed? (problem or gap today)
3. Which layers or components are affected?
4. Constraints or risks? (breaking change, migration, cross-team dependency)
5. Additional context (optional)
```

---

## Writing guidelines

**Objective:** Max ~3 sentences; affirmative verbs (implements, exposes, removes); technical benefit explicit.

**Dependencies:** Omit section if none.

**Steps:** One verifiable responsibility per step; infinitive verbs (Implement, Create, Adjust, Remove, Validate, Expose); layer order Domain -> Application -> Infrastructure -> API -> Tests; parallel steps noted as `(parallel with Step N)`.

**Acceptance criteria:** BDD with **Given / When / Then / And**; verifiable facts (e.g. HTTP 201 with payload shape), not intentions. No unit-test scenarios in acceptance criteria - QA validates behavior. No environment-variable checks as acceptance criteria.

---

## Reference example (generic)

**Objective:** Introduce a shared feature-flag provider package so services read toggles from centralized configuration instead of legacy env-only flags.

**Context:** Services duplicate env parsing; operations cannot toggle behavior without redeploy.

**Step 1 - Define `IFeatureToggle` contract in shared library** - Domain/Contracts - depends on: none.

**Step 2 - Implement configuration-backed provider** - Infrastructure - depends on: Step 1.

**AC:** Given the provider is registered, When a flag is queried in Development, Then the value matches local configuration.
