# Implement skill - reference

Detailed protocols for `skills/sdd-develop/SKILL.md`. Keep `SKILL.md` under 500 lines; use this file for templates and checklists.

PLAN must live under `features/NNN-slug/USnn/PLAN/` (or globally under `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/grok/sdd/<repo-id>/features/...`). Root/flat `PLAN/` is **not** a valid Classic SDD path - do not update it in place. Update the same feature PLAN path passed in the handoff. **Code** in the repo stays **English**. **PLAN prose** stays in the file's language (pt-BR default). See `sdd-artifact-language-pt-br.mdc` and `STORAGE.md`.

---

## PLAN update protocol

After the step’s code and targeted tests pass, edit the PLAN file in place (repo or global path).

### 1. Step block

Update the completed step section:

| Field | Value |
|-------|--------|
| Heading marker | Change `⏳` to `✅` in the step heading (optional) |
| **Status:** | `Completed` |
| **Completed:** | `YYYY-MM-DD` |
| Notes | Short bullet list: what was done, test count, caveats |

Example:

```markdown
### ✅ STEP 1: Add domain property

**Status:** Completed | **Completed:** 2026-05-21 | **Deps:** none | **Token budget:** ~20k | **Time:** 30 min

**Implementation notes:**
- Added nullable property and setter validation on Entity
- 3 unit tests: `Should_*_When_*` pattern
- `dotnet build` and filtered `dotnet test` passed
```

### 2. Deliverables and acceptance

- Check `[ ]` -> `[x]` for deliverables and acceptance items **fully** met by this step only.
- Do not check items owned by later steps.

### 3. Progress header

Update the table near the top:

```markdown
| **Progress** | 1/6 |
```

Progress bar (adjust emoji count to total steps):

```markdown
[🟢⚪⚪⚪⚪⚪] 17% (1/6)
```

### 4. Next step line

Under **Execution order** or equivalent:

```markdown
**Next step:** STEP 2 - [short title from PLAN]
```

### 5. Objectives (optional)

If an objective (O1, O2, …) is fully satisfied by this step alone, mark its checkbox `[x]`.

### 6. When not to mark Completed

- Build or targeted tests still failing
- User chose not to commit and step acceptance requires pushed commit (rare - note in PLAN)
- Dependency steps incomplete
- Session ended at context ≥ 40% **before** PLAN write - still write PLAN with **In progress** or leave Pending and note partial work in notes

### 7. Recovery

If a session crashed mid-step: set **Status:** `In progress`, list files touched in notes, resume in a new chat with the same step number.

---

## Git preparation checklist

1. `git rev-parse --abbrev-ref HEAD` - confirm not on blocked branch before edits.
2. `git status` - resolve dirty tree with user if needed.
3. Branch name matches `feature/<slug>` or `feat/<id>` (see `branch-validation.mdc`).
4. Baseline updated if user requested: `git fetch` + merge/rebase per team practice (document in PLAN notes if non-trivial).

**Blocked branch examples:** `main`, `master`, `develop`, `feature/base/foo`, `feature/parent/child`.

**Valid examples:** `feature/add-user-export`, `feat/42`.

---

## Pre-implementation code analysis

| Area | Action |
|------|--------|
| Step file list | Read each path; note namespaces, patterns, test project layout |
| Similar types | Glob for `*Entity*.cs`, handlers, consumers named like the change |
| Tests | Read one existing test class; match naming (`Should_*_When_*`), framework (xUnit), assertions (Shouldly), mocks (Moq) |
| DI registration | Grep `AddScoped`, `AddTransient`, module extensions |
| Errors | Grep `Result<`, exceptions, validation style |
| Migrations | If step includes EF: list latest migrations for naming convention |

Record answers before coding: naming language, async rules, Result vs exceptions, nullable style.

---

## .NET implementation pointers

Load on demand - do not paste into PLAN:

| Topic | File |
|-------|------|
| Layers, handlers, repositories | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/grok/skills/_shared/dotnet-guidelines/clean-architecture.md` |
| Tests, fakes, anti-patterns | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/grok/skills/_shared/dotnet-guidelines/csharp-patterns.md` |
| Pre-PR checklist | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/grok/skills/_shared/dotnet-guidelines/checklist.md` |

**Test stack (toolkit default):** xUnit, Moq, Shouldly; method names `Should_<Result>_When_<Condition>`.

**Commands (examples):**

```bash
dotnet build
dotnet test --filter "FullyQualifiedName~MyFeatureTests"
dotnet test path/to/TestProject.csproj
```

**Migrations:** when a PLAN step requires a new EF Core migration, hand off to `/ef-add-migration` (optional migration name in PascalCase). Resume the same PLAN step after migration files exist. Details: `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/grok/skills/ef-add-migration/reference.md` or `skills/ef-add-migration/reference.md` in this toolkit repo.

---

## Non-.NET stacks

Follow the step and project docs. Typical checks:

| Stack | Verify |
|-------|--------|
| Angular | `ng build` or `npm run build`; unit tests per `package.json` scripts |
| Node | `npm test` / `pnpm test` scoped to changed package |
| Other | Commands documented in repo `README` or PLAN step |

Keep PLAN updates identical regardless of stack.

---

## Session report template

Use after PLAN is saved:

```markdown
## Step N complete

**PLAN:** <full-plan-path>
**Step:** N - [title]
**Branch:** feature/... or feat/...
**Files:** [list]
**Tests:** [pass/fail summary]
**Progress:** N/M (X%)

**Next (new chat):**
/sdd-develop - <full-plan-path> - Step N+1
```

---

## Context checkpoint (mandatory)

From `context-management.mdc` after PLAN persist:

1. Update control file (PLAN).
2. Assess context usage if visible.
3. At **≥ 40%:** show pause message; do not start the next PLAN step in this session.
4. At **≥ 80%:** stop definitively; user must start new chat.

Include in pause message: saved PLAN path, last step completed, next step id/title.

---

## Optional flows (user-driven)

| After last step | User may run |
|-----------------|--------------|
| Review diff | `/code-review` |
| Commit | `/commit` |
| Open PR | GitHub web UI with repo template - no external work-item fields |

Do not auto-create PRs or link external trackers.

---

## Quality self-check (before marking Completed)

- [ ] Only this step’s scope implemented
- [ ] Tests added/updated per step and AC mapping
- [ ] Targeted build/test commands run successfully
- [ ] No forbidden patterns from `csharp-patterns.md` (if .NET)
- [ ] Branch valid per `branch-validation.mdc`
- [ ] PLAN progress and next step updated
- [ ] Context checkpoint executed

---

## Forbidden in this toolkit

| Avoid | Use instead |
|-------|-------------|
| `git clone` into `projects/{repo}` | Use open workspace only |
| `feature/base/{parent}/{child}` | `feature/<slug>` or `feat/<id>` only |
| Portuguese implement skill / `PLANO_*` filenames | `sdd-develop`, `PLAN_*` |
| NUnit-only bans in new tests | `dotnet-guidelines`, xUnit/Moq |
| Auto sync-commit with work item IDs | Optional `/commit` |
| Auto PR analyzer + work-item links | User opens PR in GitHub UI / review skill |
