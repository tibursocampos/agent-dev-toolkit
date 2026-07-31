---
name: blazor-developer
description: Implement or fix small-to-medium Blazor UI (WASM, Server, Hybrid) without full SDD. Use for isolated Blazor work or when invoking /blazor-developer.
---


## STOP - Read before ANY tool call

1. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/rules/guardrails.md`
2. Read `_shared/sdd-artifacts/SESSION.md`; load session-state for `$Cwd`
3. If the relevant gate is not approved: **STOP** - ask user **(pt-BR)** - do **NOT** Write/Shell
4. SDD/develop skills: after **ONE** step/task, **STOP** session - handoff only
5. This skill body is **English**; user-facing prompts may be **(pt-BR)**

### Step -1 - Gate check (report in chat before continuing)

```
Gate check:
[ ] guardrails.mdc read
[ ] SESSION.md read; session-state loaded
[ ] User confirmed current action (sim)
-> If any unchecked: STOP
```

---

## Trigger

Use when user asks for `/blazor-developer`, `blazor fix`, or a small isolated Blazor UI implementation.

## Outcome

Working Razor components and tests in the target workspace, validated with `dotnet build` and `dotnet test`, with optional handoff to `/commit`.

## Blazor host detection

Inspect `.csproj` and project layout:

| Signal | Host |
|--------|------|
| `Microsoft.AspNetCore.Components.WebAssembly` | **WASM** - client-side; API calls via HttpClient |
| `InteractiveServer` / Blazor Server SDK | **Server** - SignalR circuit; avoid long-blocking UI thread |
| `Microsoft.Maui` + BlazorWebView | **Hybrid** - native shell; note platform constraints in implementation |

Also detect via `_Imports.razor`, `App.razor`, or `Routes.razor`.

## When to escalate to SDD

Recommend `sdd-spec` -> `sdd-plan` -> `sdd-develop` if two or more apply: 3+ layers touched, new API contracts, cross-repo impact, 10+ files, or existing approved PLAN.

**Use `dotnet-developer`** for non-UI .NET (APIs, services, EF, messaging).

## DESIGN-BRIEF acceptance

If `docs/DESIGN-BRIEF.md` or `docs/design/DESIGN-BRIEF.md` exists, treat it as the acceptance source. Map sections to Razor components/layouts; do **not** reinterpret visual decisions. Implement **one session scope** from section 10 only.

For Hybrid targets, note platform-specific constraints in section 9 of the brief.

If the task is net-new UI without a brief, recommend `/impeccable shape` in a **new session** before implementing.

## Lazy-load references

| When | Path |
|------|------|
| Design brief | `docs/DESIGN-BRIEF.md` or `docs/design/DESIGN-BRIEF.md` |
| Branch / commit | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/rules/branch-validation.mdc`, `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/skills/_shared/developer-common/step-3-branching.md` |
| Blazor components / lifecycle | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/skills/_shared/blazor-guidelines/blazor-components.md` |
| Blazor state / forms | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/skills/_shared/blazor-guidelines/blazor-state.md` |
| Blazor render modes | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/skills/_shared/blazor-guidelines/blazor-render-modes.md` |
| Blazor JS interop | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/skills/_shared/blazor-guidelines/blazor-js-interop.md` |
| Blazor routing / auth | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/skills/_shared/blazor-guidelines/blazor-routing-auth.md` |
| Blazor performance | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/skills/_shared/blazor-guidelines/blazor-performance.md` |
| Blazor testing (bUnit) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/skills/_shared/blazor-guidelines/blazor-testing.md` |
| Blazor delivery checklist | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/skills/_shared/blazor-guidelines/checklist.md` |
| Frontend core | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/skills/_shared/frontend-guidelines/frontend-practices.md` |
| FE structure (ARCH / CONTINUITY needs folder layout) | Prefer `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/skills/_shared/frontend-guidelines/frontend-architecture.md` — **not** a per-framework CA tree |
| Markup / styles | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/skills/_shared/html-css-guidelines/` |
| .NET patterns | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/skills/_shared/dotnet-guidelines/csharp-patterns.md` |
| API rings (when Blazor + concentric .NET API) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/skills/_shared/dotnet-guidelines/clean-architecture.md` — only if ARCH = concentric |
| Principles | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/skills/_shared/code-guidelines/principles/principles-cheatsheet.md` (+ `architecture-selection.md` or **one** approved style — never glob `architecture/**`) |
| Context | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/rules/context-management.mdc` |
| Subagent-first / SPAWN.md | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/skills/_shared/developer-common/subagent-first.md`, `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/skills/_shared/agents/SPAWN.md` |
| Caveman Mode (if active) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/skills/_shared/caveman/CAVEMAN.md` |

Do not preload unrelated guideline trees. Load only the `blazor-guidelines` rows needed for the current task.

## Process

### Step -1b - Caveman Mode (Full cap)
1. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/sdd/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full" }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/skills/_shared/caveman/CAVEMAN.md`; apply **Full** participation cap + prefs `caveman_level` (Lite skills never escalate); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) during the session.
5. Auto-Clarity + never-compress gates/drafts/paths per `CAVEMAN.md`.

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

## Must not

- Paste guideline packs into child prompts (pass scoped **paths** + require **receipt** only)
- Spawn children for **trivial** work (keep **in-parent**)
- Hard-fail when capability `subagents` is `none` or Task is unavailable (use **fallback** **in-parent**)
- Auto-commit or auto-PR
- Leave AI traces in code or identifiers
- Block Blazor Server UI thread with long synchronous work

## Handoff

| Situation | Next |
|-----------|------|
| Commit | `/commit` |
| Review | `/code-review` |
| Backend / API only | `/dotnet-developer` |
| Scope grew | `sdd-spec` -> `sdd-plan` -> `sdd-develop` |
| Missing design brief | `/impeccable shape` (new session) |
