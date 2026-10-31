# blazor-developer — execute flow

Read this file for procedural detail. Do not dump stack guideline packs into chat or child prompts — lazy-load **one** guideline file when that surface is in scope.

### Subagent-first (before implement)

Classify complexity → consult capability `subagents` → if medium/complex and `native`: spawn ≤2 children (scoped **paths** + **receipt**); **trivial** stays **in-parent**; if `subagents=none` or Agent unavailable → **fallback** **in-parent** (never hard-fail). Load `SPAWN.md` + `subagent-first.md`; do not paste guidelines into child prompts.

### 0. Workspace

Confirm Blazor project markers. Identify host (WASM / Server / Hybrid). Read `README.md`, summarize acceptance.

### 1. Guidelines

Load Blazor and frontend guidelines for this task.

### 2. Branch

Use the repository's work-branch convention. Never commit on `main`/`master`/`develop`.

### 3. Micro-plan

Checkpoint durable workflow progress at the workflow-defined boundaries; context usage does not add a stop gate.

### 4. Implement

Discover architectural patterns in the touched area first. Follow `structure-and-quality.md` §1: an operator order and the established project style outrank the toolkit style bar. Do not restyle existing members without an explicit yes. On greenfield / no clear comment-language mirror, ask before writing narrative comments/docs (identifiers stay English).

Razor components, parameters, `@bind`, lifecycle. Match existing patterns (code-behind vs inline per project).

### 5. Tests

Match the repository's test stack for component logic. Use bUnit when already referenced or when no test baseline exists and component tests are needed; use Playwright for E2E only when the project has E2E setup.

### 6. Validate

```bash
dotnet build
dotnet test
```

### 7. Handoff

Offer `/commit`. Do not commit automatically.
