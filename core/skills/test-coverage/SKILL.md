---
name: test-coverage
description: Run .NET Coverlet coverage, report Sonar-aligned metrics, and evaluate against a threshold (default 80%). Use for coverage reports or when invoking /test-coverage.
---

## STOP - Read before ANY tool call

1. Read `{{GUARDRAILS_PATH}}`
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
| Reference index (routing only) | `{{TOOLKIT_ROOT}}/skills/test-coverage/reference.md` |
| Process step detail (lazy) | `{{TOOLKIT_ROOT}}/skills/test-coverage/references/<section>.md` |
| Cursor mode (Agent for shell) | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/PIPELINE.md` section Cursor mode |
| Caveman Mode (if active) | `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md` - **Full cap** |
| Add tests for gaps | `{{TOOLKIT_ROOT}}/skills/_shared/dotnet-guidelines/csharp-patterns.md` |
| Commit | `/commit` |

**Never by default:** do not preload all `references/*.md` or full guideline packs. Load **one** section file per Process step — never full `reference.md` when a section exists (`SKILL-REFERENCE-RETRIEVAL.md`).

## Reference routing

| Situation | Path |
|-----------|------|
| Prerequisites | `references/prerequisites.md` |
| Exclusions | `references/exclusions.md` |
| Commands | `references/commands.md` |
| Metrics | `references/metrics.md` |
| On-disk artifacts | `references/artifacts.md` |
| Report template | `references/report-template.md` |
| Scoped discovery | `references/scoped-discovery.md` |
| Integrations | `references/integrations.md` |
| Troubleshooting | `references/troubleshooting.md` |
## Process

Read `references/<section>.md` for commands, metrics, and templates — **not** full `reference.md`.

### Step -1b - Caveman Mode (Full cap)
1. Read `{{SDD_ROOT}}/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full" }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md`; apply **Full** participation cap + prefs `caveman_level` (Lite skills never escalate); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) during the session.
5. Auto-Clarity + never-compress gates/drafts/paths per `CAVEMAN.md`.

### -1. Mode
`PIPELINE.md`: **Agent** required for `dotnet test` and ReportGenerator. In Plan/Ask, explain limitation and list expected paths under `TestResults/` after the user switches to Agent.

### 0. Workspace
Confirm **target .NET repository** (`.sln` or `*Tests.csproj`). If the workspace is `agent-dev-toolkit` only (no test projects), stop and ask which consumer repo to open. Detect stack; read `AGENTS.md` / `README.md` when present.

### 1. Resolve scope
**Base branch:** user argument, or `main` / `develop` (ask once if ambiguous).

```bash
git fetch origin   # when remote comparison is needed
git rev-parse --abbrev-ref HEAD
git diff <base>...HEAD --name-only -- "*.cs"
```

Filter to **production** changed files per `references/exclusions.md`. Record the list for per-file metrics. Large repos: see `references/scoped-discovery.md`.

### 2. Prerequisites check
Before running tests, verify per `references/prerequisites.md`. If `coverlet.collector` is missing, stop with install instructions - do not fail silently.

### 3. Collect coverage (mandatory ReportGenerator)
1. Run `dotnet test` with Coverlet -> `TestResults/**/coverage.cobertura.xml` per `references/commands.md`.
2. **Always** run ReportGenerator -> `TestResults/CoverageReport/` (`Summary.txt`, `index.html`, Cobertura). Do not finish with XML only.
Use scoped test project when the repo is large or user provided a path.

### 4. Compute metrics
Parse Cobertura / ReportGenerator output per `references/metrics.md` (new code / overall branch / per-file). Exclude migrations, generated code, and test projects from **new code** denominator (`references/exclusions.md`).

### 5. Evaluate threshold
| Result | When |
|--------|------|
| **Pass** | New code coverage >= threshold (default 80%) |
| **Fail** | New code coverage < threshold |
Always note distance to **target 100%** for files below 100% even when Pass.

### 6. Report (chat + on-disk artifacts)
Use `references/report-template.md`. Cite paths from `references/artifacts.md`. **Required in chat:** Summary.txt / index.html / cobertura paths, Resumo table, commands, limitations, approval block (Pass) or gaps (Fail). Do not claim Pass if ReportGenerator output or Cobertura files are missing. Integrations: `references/integrations.md`. Troubleshooting: `references/troubleshooting.md`.

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
