---
name: dotnet-developer
description: Implement or fix small-to-medium .NET features without full SDD (Clean Architecture, xUnit). Use for isolated C# work or when invoking /dotnet-developer.
---

## STOP - Read before ANY tool call

1. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/rules/guardrails.mdc`
2. Read `_shared/sdd-artifacts/SESSION.md`; load session-state for `$Cwd`
3. If the relevant gate is not approved: **STOP** - ask user **(pt-BR)** - do **NOT** Write/Shell
4. SDD/develop skills: after **ONE** step/task, **STOP** session - handoff only
5. This skill body is **English**; user-facing prompts may be **(pt-BR)**

### Step -1 - Gate check (report in chat before continuing)

```
Gate check:
[ ] guardrails.mdc read
[ ] SESSION.md read; session-state loaded
[ ] PIPELINE.md read (SDD skills only)
[ ] User confirmed current action (sim)
-> If any unchecked: STOP
```

---

## Trigger

Invoke when the user asks for: `/dotnet-developer`, `dotnet fix`, `implement .NET feature`, or for **small** backend work that does not need a full PRD/PLAN cycle.

## Outcome

Working **.NET** code and tests in the open workspace: build and tests green, on a valid feature branch, with optional commit handoff. Does not replace SDD for multi-step or cross-repo features.

## When to prefer SDD instead

Recommend `/sdd-spec` -> `sdd-plan` -> `sdd-develop` if **two or more** apply:

| Signal | Indicator |
|--------|-----------|
| Layers | 3+ layers (Domain, Application, Infrastructure, API) |
| Database | New or altered schema / migrations |
| Repos | Backend and another repo or service |
| Integrations | New messaging, external APIs, or consumers |
| Size | 10+ files or estimated 4+ hours |
| PLAN exists | User already has an approved PLAN - use `sdd-develop` |

## Lazy-load (only when needed)

| When | Path (after `scripts/sync-cursor.ps1`) |
|------|----------------------------------------|
| Repo context | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/developer-common/step-0-context.md` |
| Before coding | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/developer-common/step-0.5-review-guidelines.md` |
| Branching | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/rules/branch-validation.mdc`, `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/developer-common/step-3-branching.md` |
| Pre-commit | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/developer-common/step-3.5-precommit-validation.md` |
| Commit / PR | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/developer-common/step-4-commits-pr.md`, `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/rules/conventional-commits.mdc` |
| Pre-PR gate | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/developer-common/step-7-checklist.md` |
| Architecture (greenfield / style unset) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/code-guidelines/principles/architecture-selection.md` — then **one** approved style only |
| Architecture (ARCH = concentric / CA / onion / hexagonal) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/dotnet-guidelines/clean-architecture.md` (+ optional `principles/architecture/concentric-dependency.md`) |
| Architecture (ARCH = vertical-slice / VSA) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/dotnet-guidelines/vertical-slice.md` (+ optional `principles/architecture/vertical-slice.md`) |
| Architecture (ARCH = ddd / tactical DDD) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/dotnet-guidelines/ddd-tactical.md` (+ optional `principles/architecture/ddd-tactical.md`) |
| Architecture (ARCH = event-driven / EDA) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/dotnet-guidelines/event-driven.md` (+ optional `principles/architecture/event-driven.md`) |
| C# / tests | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/dotnet-guidelines/csharp-patterns.md` |
| Subagent-first / SPAWN.md | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/developer-common/subagent-first.md`, `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/agents/SPAWN.md` |
| Caveman Mode (if active) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/caveman/CAVEMAN.md` - **Full cap** |
| Final checklist | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/dotnet-guidelines/checklist.md` |
| Context pressure | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/rules/context-management.mdc` |

Do **not** preload `code-guidelines/languages/**` or corporate pipeline docs. **MUST NOT** glob `architecture/**` — load **one** style overlay from ARCH/CONTINUITY (brownfield: discover-first if style omitted).

## Process

### Step -1b - Caveman Mode (Full cap)
1. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/sdd/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full" }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/caveman/CAVEMAN.md`; apply **Full** participation cap + prefs `caveman_level` (Lite skills never escalate); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) during the session.
5. Auto-Clarity + never-compress gates/drafts/paths per `CAVEMAN.md`.

### Subagent-first (before implement)

Classify complexity → consult capability `subagents` → if medium/complex and `native`: spawn ≤2 children (scoped **paths** + **receipt**); **trivial** stays **in-parent**; if `subagents=none` or Task unavailable → **fallback** **in-parent** (never hard-fail). Load `SPAWN.md` + `subagent-first.md`; do not paste guidelines into child prompts.

### 0. Workspace

Confirm target repo (`*.sln` / `*.csproj`). Read `AGENTS.md` / `README.md`. Summarize the user request and acceptance (from issue text, PRD snippet, or user description).

### 1. Guidelines (step 0.5)

Follow `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/developer-common/step-0.5-review-guidelines.md`: load `dotnet-guidelines` files needed for this task only. Confirm test stack: **xUnit**, **Moq**, **Shouldly**, `Should_<Result>_When_<Condition>`.

### 2. Branch (step 3)

Baseline branch from user or repo default. Create/checkout `feature/<slug>` or `feat/<id>` - never commit on `main` / `master` / `develop`.

### 3. Plan micro-steps

List 3-7 concrete tasks (files to touch, tests to add). Stay within one session when possible; checkpoint per `context-management.mdc` (>= 40% -> pause, offer `/commit`).

### 4. Implement

Match existing project patterns (Glob/Read similar types first).

| Layer | Typical work |
|-------|----------------|
| Domain | Entities, value objects, domain services |
| Application | Commands/queries, handlers, validators |
| Infrastructure | EF, repositories, external clients |
| API | Endpoints, DTOs, auth filters |

Apply the **one** ARCH-matched architecture overlay (see lazy-load table) and `csharp-patterns.md` from `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/dotnet-guidelines/` while writing - do not paste full bodies into chat. Never glob `architecture/**`.

### 5. Tests

Add or update tests for changed behavior. Prefer integration tests for real flows when the project already uses them; unit tests for isolated logic.

### 6. Build and test

```bash
dotnet build
dotnet test --no-build
```

Fix failures within scope. Ask before running full-solution tests if the repo is very large.

### 7. Pre-commit (step 3.5) and handoff

Run `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/developer-common/step-3.5-precommit-validation.md` when appropriate. Offer `/commit` - do not commit automatically.

Before push/PR, run `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/developer-common/step-7-checklist.md` and `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/dotnet-guidelines/checklist.md`.

### 8. SDD escalation

If scope grows during work, stop and recommend:

```
/sdd-spec - [feature description]
# then
/sdd-plan - PRD/...
# then
/sdd-develop - PLAN/... - Step 1
```

## Must not

- Paste guideline packs into child prompts (pass scoped **paths** + require **receipt** only)
- Spawn children for **trivial** work (keep **in-parent**)
- Hard-fail when capability `subagents` is `none` or Task is unavailable (use **fallback** **in-parent**)
- External work-item APIs, `repo-mappings.json`, or org-only pipeline/Key Vault mapping guides
- Obsolete test stacks or naming conventions (use xUnit/Moq/`Should_When_` only)
- Obsolete guideline paths (use `dotnet-guidelines/` only)
- Nested `feature/base/...` branches; commit on default integration branches
- Speculative features outside stated acceptance (YAGNI)
- Auto-commit or auto-PR without user request
- Deprecated SDD skill aliases in handoff text - use `sdd-spec`, `sdd-plan`, `sdd-develop`, `commit` only

## Handoff

| Situation | Next |
|-----------|------|
| Commit | `/commit` |
| Review | `/code-review` |
| Large scope | `/sdd-spec` -> `sdd-plan` -> `sdd-develop` |
| Next PLAN step | New chat -> `/sdd-develop - PLAN/... - Step N` |
