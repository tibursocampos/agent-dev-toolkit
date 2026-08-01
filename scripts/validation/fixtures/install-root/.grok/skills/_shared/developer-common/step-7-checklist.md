# Step 7: Pre-PR / pre-push checklist

**Goal:** Confirm quality and Git hygiene before push or PR.

---

## 7.1. Preparation (steps 0-0.5)

- [ ] `AGENTS.md` / `README.md` reviewed when present
- [ ] Guidelines reviewed (principles + stack files loaded as needed)
- [ ] High-level task list reflects current state

---

## 7.2. Branching (step 3)

- [ ] On `feature/<slug>` or `feat/<id>` - not on `main` / `master` / `develop`
- [ ] No nested `feature/parent/child` branch names
- [ ] Changes belong to the current feature scope

---

## 7.3. Implementation

- [ ] Code matches project conventions and PLAN/PRD acceptance (if SDD)
- [ ] Tests added or updated for behavior changes
- [ ] Build passes
- [ ] Tests pass (unit scope at minimum)

---

## 7.4. SDD traceability (when PLAN exists)

- [ ] PLAN step deliverables and acceptance checkboxes addressed
- [ ] Only one PLAN step claimed per session (implement skill)
- [ ] PLAN file updated with completion notes before handoff

---

## 7.5. Quality

- [ ] Clear naming; reasonable method size; focused types
- [ ] No obvious security issues (secrets, injection, sensitive logs)
- [ ] No egregious performance issues (N+1, unbounded loops) in touched code

---

## 7.6. Commits and PR (step 4)

- [ ] Conventional commit message(s)
- [ ] No Cursor `Co-authored-by` trailers (`--trailer` or message footer)
- [ ] Pre-commit validation run (step 3.5) or user acknowledged skip
- [ ] Push only if user requested
- [ ] PR only if user requested; base branch confirmed

---

## 7.7. Stack commands

| Stack | Blockers | Optional |
|-------|----------|----------|
| .NET | `dotnet build`, `dotnet test` (scoped) | `dotnet format --verify-no-changes` |
| Node | `npm run build`, `npm test` | `npm run lint` |
| Python | `pytest` (project venv) | `ruff` / `mypy` when configured |

---

## Blockers vs warnings

| Type | Examples | Action |
|------|----------|--------|
| **Blocker** | Build fail, tests fail, wrong branch, secrets | Fix before push/PR |
| **Warning** | Coverage below team target, minor lint | Document in PR body or PLAN notes |

---

## Step 7 checklist

- [ ] All blockers resolved
- [ ] Warnings acknowledged
- [ ] User informed of next action (push, PR, or next PLAN step in new chat)
