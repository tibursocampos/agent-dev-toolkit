# Developer common - Git workflow reference

Shared steps for dev skills (`sdd-develop`, `commit`, `code-review`, `developer`). Load only the steps your skill needs.

**Version:** 2.0.0 (cursor-dev-toolkit)  
**Scope:** Git-only - no work-item trackers, no corporate PR APIs.

Install path after sync: `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/developer-common/`

---

## File layout

```
developer-common/
├── GUIDE.md                         # This file
├── step-0-context.md                # AGENTS.md / README, task list
├── step-0.5-review-guidelines.md    # Lazy-load principles + stack guidelines
├── step-3-branching.md              # feature/<slug> or feat/<id>
├── step-3.5-precommit-validation.md # Secrets, lint, build, quick tests
├── step-4-commits-pr.md             # Conventional commits; optional GitHub PR
├── step-7-checklist.md              # Pre-commit / pre-PR checklist
└── templates/
    └── todo-list.md                 # High-level task template
```

**Not in this toolkit:** work-item tracker integration, time estimation, progress trackers, wiki docs, PR analyzer, nested `feature/base/{id}` branches.

---

## How skills reference these steps

In a skill `SKILL.md`, point to a step file instead of inlining:

```markdown
### Git branch

Follow `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/developer-common/step-3-branching.md`.
```

Override only stack-specific commands (e.g. `dotnet test` vs `npm test`).

---

## Execution flow (Git-only)

```
┌──────────────────────────────────────────────────────────────┐
│ Step 0: Repository context                                   │
│ - Read AGENTS.md / README.md                                 │
│ - Create high-level task list                                │
├──────────────────────────────────────────────────────────────┤
│ Step 0.5: Review guidelines (before coding)                  │
│ - principles/ cheatsheet (lazy)                              │
│ - dotnet-guidelines when .NET (lazy)                         │
├──────────────────────────────────────────────────────────────┤
│ Step 3: Branching                                            │
│ - feature/<slug> or feat/<id> from baseline branch           │
├──────────────────────────────────────────────────────────────┤
│ Step 3.5: Pre-commit validation                              │
│ - Secrets, format, build, quick tests                        │
├──────────────────────────────────────────────────────────────┤
│ Step 4: Commits (and optional PR)                            │
│ - Conventional Commits; push; open PR in GitHub UI if user asks │
├──────────────────────────────────────────────────────────────┤
│ Step 7: Final checklist                                      │
│ - Build, tests, branch, commit message                       │
└──────────────────────────────────────────────────────────────┘
```

SDD skills (`sdd-spec`, `sdd-plan`, `sdd-develop`) embed parts of this flow inline; dev skills load step files on demand.

---

## Mapping to Cursor rules

| Step | Rule / skill |
|------|----------------|
| 3 | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/rules/branch-validation.mdc` |
| 4 | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/rules/conventional-commits.mdc`, `commit` skill |
| Context | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/rules/context-management.mdc` |
| SDD PLAN | `sdd-develop` skill |

Rules win over conflicting text in step files.

---

## Quality principles (all stacks)

- Descriptive naming; short methods; single responsibility
- SOLID where applicable; injectable dependencies; deterministic tests
- No secrets in source; validate external input; parameterized queries
- Structured logging without sensitive data

Stack-specific detail: `dotnet-guidelines/` or project `docs/`.
