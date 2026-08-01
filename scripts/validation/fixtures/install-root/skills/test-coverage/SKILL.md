---
name: test-coverage
description: Run .NET Coverlet coverage, report Sonar-aligned metrics, and evaluate against a threshold (default 80%). Use for coverage reports or when invoking /test-coverage.
---

## STOP - Read before ANY tool call

1. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/rules/guardrails.mdc`
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

Invoke when the user asks for: `/test-coverage`, `coverage report`, `coverage`, or when a PLAN step / `code-review` requires coverage evidence.

**Arguments (optional):**

| Input | Meaning |
|-------|---------|
| Base branch | `main`, `develop` - ask once if missing (same as `code-review`) |
| Test project path | `path/to/Tests.csproj` - auto-detect `*Tests.csproj` / `*.Tests.csproj` if omitted |
| Threshold | Minimum line coverage on **changed production `.cs` files** (default: **80**) |
| Target | **100** - aspirational; document gaps when below 100 but >= threshold |

## Outcome

A structured **coverage report** in **pt-BR** with:

- **Coverage on new code** - line coverage on changed production files vs base branch
- **Overall branch coverage** - solution-wide line coverage after tests
- **Per-file breakdown** - each changed production file with line %
- **Decision:** Pass (>= threshold) or Fail (< threshold) with gap list

Does not modify code unless the user asks for test additions in a follow-up.

## Lazy-load

| When | Path |
|------|------|
| Commands, parsing, exclusions, on-disk report paths | `test-coverage/reference.md` after sync |
| Cursor mode (Agent for shell) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/sdd-artifacts/PIPELINE.md` section Cursor mode |
| Caveman Mode (if active) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/caveman/CAVEMAN.md` - **Full cap** |
| Add tests for gaps | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/dotnet-guidelines/csharp-patterns.md` |
| Commit | `/commit` |

## Process

### Step -1b - Caveman Mode (Full cap)
1. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/sdd/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full" }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/caveman/CAVEMAN.md`; apply **Full** participation cap + prefs `caveman_level` (Lite skills never escalate); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) during the session.
5. Auto-Clarity + never-compress gates/drafts/paths per `CAVEMAN.md`.

### -1. Mode

`PIPELINE.md`: **Agent** required for `dotnet test` and ReportGenerator. In Plan/Ask, explain limitation and list expected paths under `TestResults/` after the user switches to Agent.

### 0. Workspace

Confirm **target .NET repository** (`.sln` or `*Tests.csproj`). If the workspace is `agent-dev-toolkit` only (no test projects), stop and ask which consumer repo to open.

Detect stack; read `AGENTS.md` / `README.md` when present.

### 1. Resolve scope

**Base branch:** user argument, or `main` / `develop` (ask once if ambiguous).

```bash
git fetch origin   # when remote comparison is needed
git rev-parse --abbrev-ref HEAD
git diff <base>...HEAD --name-only -- "*.cs"
```

Filter to **production** changed files per `reference.md` section Exclusions. Record the list for per-file metrics.

### 2. Prerequisites check

Before running tests, verify per `reference.md` section Prerequisites:

- `coverlet.collector` on test project(s)
- `dotnet test` succeeds
- `reportgenerator` global tool (install once if missing)

If `coverlet.collector` is missing, stop with install instructions - do not fail silently.

### 3. Collect coverage (mandatory ReportGenerator)

1. Run `dotnet test` with Coverlet -> `TestResults/**/coverage.cobertura.xml` per `reference.md` section Commands.
2. **Always** run ReportGenerator -> `TestResults/CoverageReport/` (`Summary.txt`, `index.html`, Cobertura). Do not finish with XML only.

Use scoped test project when the repo is large or user provided a path.

### 4. Compute metrics

Parse Cobertura / ReportGenerator output per `reference.md` section Metrics:

| Metric | Definition |
|--------|------------|
| **New code** | Weighted line coverage on changed production `.cs` files |
| **Overall branch** | Line coverage across included assemblies |
| **Per-file** | Line % per changed production file |

Exclude migrations, generated code, and test projects from **new code** denominator (see reference).

### 5. Evaluate threshold

| Result | When |
|--------|------|
| **Pass** | New code coverage >= threshold (default 80%) |
| **Fail** | New code coverage < threshold |

Always note distance to **target 100%** for files below 100% even when Pass.

### 6. Report (chat + on-disk artifacts)

Use the template in `reference.md`. **Required in chat:**

- Workspace-relative paths to `TestResults/CoverageReport/Summary.txt`, `index.html` (if generated), and at least one `coverage.cobertura.xml`
- Key table from `Summary.txt` (paste **Resumo** section)
- Commands run, limitations, approval block (Pass) or gaps (Fail)

Do not claim Pass if ReportGenerator output or Cobertura files are missing.

### 7. Handoff

| Situation | Next |
|-----------|------|
| Pass | `/code-review` - paste approval block from report |
| Fail - add tests | `/dotnet-developer` or `/sdd-develop` |
| Build/test broken | `/repair-dotnet-build` |
| Commit coverage tooling in consumer repo | `/commit` |
| SDD feature with PLAN | Last PLAN step or `code-review` after all `sdd-develop` steps |
| Small fix | `/dotnet-developer` to raise coverage, then re-run this skill |

## Must not

- Require SonarLint, Visual Studio, SonarQube login, or corporate pipeline APIs
- Auto-commit, auto-push, or add tests without user request
- Claim Pass when tests did not run, coverlet output is missing, or ReportGenerator was skipped
- Deliver coverage **only** in chat without citing on-disk paths under `TestResults/`
- Count EF migrations, `*.g.cs`, or `*.Designer.cs` in new-code denominator
- Block merge by itself - gate is informational unless PRD/PLAN/`code-review` applies threshold
