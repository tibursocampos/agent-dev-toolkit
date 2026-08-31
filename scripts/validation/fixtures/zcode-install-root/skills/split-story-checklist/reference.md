# split-story-checklist - reference

Grouping heuristics and templates for `skills/split-story-checklist/SKILL.md`. Keep `SKILL.md` under 500 lines; use this file for extended detail.

---

## Parsing steps from refined markdown

| Item type | Section headings to search |
|-----------|
| User Story / Technical Story | `### Steps` (emoji heading variants allowed) |
| STORY.md | `## Steps` or steps embedded after description |
| Bug | `### Suggested fix` or `### Steps` |

Each step block typically matches:

```markdown
**Step N - [Title]**
[description]
- Layer: [...]
- Depends on: [...]
```

Also accept legacy Portuguese headings: `**Etapa N -` (normalize to Step N in output).

If only a bullet list without step headers, ask the user to re-run `refine-story` or confirm grouping manually.

---

## Topological order (story checklist portable)

1. Build a directed graph from `Depends on: Step N` / `none`.
2. Reject cycles - ask user to fix deps before writing the file.
3. Assign **waves**: wave 0 = no deps; wave k = all deps in earlier waves.
4. Within a wave, apply layer/repo grouping below.
5. Document parallel-safe steps: same wave and different groups with no cross edges.

Do **not** invent external work-item predecessor links or fixed org-only stage names.

---

## Grouping heuristics

Apply in order **after** topology waves:

**a) Markdown sub-headings (`####`)** - e.g. `#### Backend - billing-api` -> one group per heading.

**b) Repository / service name** - steps mentioning different repos or deployable units group separately.

**c) Layer** - same repo but clear split: Domain/Application/Infrastructure/API -> "Backend"; UI/Angular/React -> "Frontend".

**d) Fallback** - ≤3 steps with no natural split -> single group `Implementation`.

**Limits:**

- Maximum **5** implementation groups - merge smallest adjacent groups if exceeded
- Minimum **1** implementation group when any non-test steps exist

**Test steps (mandatory split):**

Steps whose layer is `Tests`, `Integration tests`, `Testes`, or title contains "unit test" / "integration test" -> move to:

- `Tests - Backend` and/or
- `Tests - Frontend`

Do not leave test-only steps inside feature implementation groups.

---

## Output template (preferred: feature story)

`features/NNN-slug/USnn/REFINE/tasks.md`:

```markdown
# Implementation tasks: [title]

| Field | Value |
|-------|--------|
| **Source** | features/.../STORY.md \| docs/backlog/<slug>.md \| chat |
| **Doc language** | pt-BR \| English |
| **Repository** | [name] |
| **Progress** | 0/N groups |

## Summary

| Group | Steps | Wave | Status |
|-------|-------|------|--------|
| Implement [Group 1] | 1-3 | 0 | Pending |
| Implement [Group 2] | 4-5 | 1 | Pending |
| Tests - Backend | 6 | 2 | Pending |

---

## Implementation

### Group 1: [name]

**Steps covered:** 1-2 | **Wave:** 0 | **Parallel-safe with:** none

- [ ] **Step 1 - [title]**
  - Layer: [...]
  - Depends on: none
- [ ] **Step 2 - [title]**
  - Layer: [...]
  - Depends on: Step 1

---

## Tests

### Tests - Backend

**Steps covered:** 5 | **Wave:** 2

- [ ] **Step 5 - [title]**

---

## Before PR (optional - neutral checklist)

- [ ] Build and targeted tests pass locally
- [ ] Acceptance criteria from story/backlog re-read
- [ ] PR description lists scope and test evidence
- [ ] No secrets or local paths in diff

---

## Execution order

**Critical path:** Wave 0 -> Wave 1 -> … -> Tests

**Parallel waves:** list step ids that may run together

**Next:** Group 1 - [name]

## SDD / Orchestrated Delivery handoff

```
/sdd-spec -> /sdd-plan -> /sdd-develop
```

or

```
/orchestrate-analyze
```

This file does **not** replace `features/.../PLAN/PLAN_*.md`.
```

Shortcut path `docs/implementation-tasks/<slug>.md` (or legacy `docs/sdd-developation-tasks/`) uses the same body.

---

## SDD PLAN resolution (read-only)

When the handoff table says **PLAN already exists**, resolve the path before suggesting `sdd-develop`:

1. Load `STORAGE.md`.
2. Glob `features/**/PLAN/PLAN_*.md` only (workspace + global feature root).
3. Do **not** resolve root/flat `PLAN/PLAN_*.md` or `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/sdd/<repo-id>/PLAN/` for execution.
4. If the user named a feature or `NNN`, pick the matching file under `features/`.
5. If zero or multiple remain, ask once in pt-BR with numbered full paths.
6. Pass **full path** in the handoff.

Do **not** use `docs/documentation-plan/plan.md`.

---

## Boundary: split-story-checklist vs plan vs O2

| Aspect | `split-story-checklist` | `sdd-plan` | `orchestrate-deliver` (O2) |
|--------|-------------------|------------|----------------------------|
| Input | Refined steps / STORY | PRD | Approved US/TS backlog |
| Output | Local checklist | `PLAN_*.md` under feature | PRD+PLAN per story |
| Granularity | Engineering groups + waves | Baby steps + token budget | Multi-story orchestration |
| Tracker | Never | Never | Never |

---

## Explicit exclusions (derived from checklist planning patterns)

Do **not** auto-generate:

- "Update AI tags" / SDD / DevAI tag tasks
- "Attach Datadog logs" as a fixed task
- manual sign-off checklist / DESKCHECK tag tasks
- "Review own PR" with Sonar/Snyk boilerplate as mandatory rows
- Child tasks on remote boards via external tracker REST/CLI

If the user wants a custom workflow section, add it under **Before PR** with their wording only.

---

## Context management

Per `context-management.mdc`: after writing a large checklist, checkpoint at ≥ 40% context; hand off continuation with file path and next group id.
