# blazor-developer — execute flow

Read this file for procedural detail. Do not dump stack guideline packs into chat or child prompts — lazy-load **one** guideline file when that surface is in scope.

### Subagent-first (before implement)

Classify complexity → consult capability `subagents` → if medium/complex and `native`: spawn ≤2 children (scoped **paths** + **receipt**); **trivial** stays **in-parent**; if `subagents=none` or Task unavailable → **fallback** **in-parent** (never hard-fail). Load `SPAWN.md` + `subagent-first.md`; do not paste guidelines into child prompts.

### 0. Workspace

Confirm Blazor project markers. Identify host (WASM / Server / Hybrid). Read `README.md`, summarize acceptance.

### 1. Guidelines

Load Blazor and frontend guidelines for this task.

### 2. Branch

Use `feature/<slug>` or `feat/<id>`. Never commit on `main`/`master`/`develop`.

### 3. Micro-plan

Define 3-7 concrete tasks; checkpoint context at >= 40%.

### 4. Implement

Razor components, parameters, `@bind`, lifecycle. Match existing patterns (code-behind vs inline per project).

### 5. Tests

bUnit for component logic; Playwright for E2E when the project has E2E setup.

### 6. Validate

```bash
dotnet build
dotnet test
```

### 7. Handoff

Offer `/commit`. Do not commit automatically.
