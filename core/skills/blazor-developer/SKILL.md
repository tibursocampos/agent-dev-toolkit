---
name: blazor-developer
description: Implement or fix small-to-medium Blazor UI (WASM, Server, Hybrid) without full SDD. Use for isolated Blazor work or when invoking /blazor-developer.
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
[ ] User confirmed current action (sim)
-> If any unchecked: STOP
```

---

# Skill: blazor-developer

## Trigger

Use when user asks for `/blazor-developer`, `blazor fix`, or a small isolated Blazor UI implementation.

## Outcome

Working Razor components and tests in the target workspace, validated with `dotnet build` and `dotnet test`, with optional handoff to `/commit`.

## Lazy-load (only when needed)

| When | Path (after `scripts/sync-cursor.ps1`) |
|------|----------------------------------------|
| Design brief | `docs/DESIGN-BRIEF.md` or `docs/design/DESIGN-BRIEF.md` |
| Branch / commit | `{{TOOLKIT_ROOT}}/rules/branch-validation.mdc`, `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-3-branching.md` |
| Blazor components / lifecycle | `{{TOOLKIT_ROOT}}/skills/_shared/blazor-guidelines/blazor-components.md` |
| Blazor state / forms | `{{TOOLKIT_ROOT}}/skills/_shared/blazor-guidelines/blazor-state.md` |
| Blazor render modes | `{{TOOLKIT_ROOT}}/skills/_shared/blazor-guidelines/blazor-render-modes.md` |
| Blazor JS interop | `{{TOOLKIT_ROOT}}/skills/_shared/blazor-guidelines/blazor-js-interop.md` |
| Blazor routing / auth | `{{TOOLKIT_ROOT}}/skills/_shared/blazor-guidelines/blazor-routing-auth.md` |
| Blazor performance | `{{TOOLKIT_ROOT}}/skills/_shared/blazor-guidelines/blazor-performance.md` |
| Blazor testing (bUnit) | `{{TOOLKIT_ROOT}}/skills/_shared/blazor-guidelines/blazor-testing.md` |
| Blazor delivery checklist | `{{TOOLKIT_ROOT}}/skills/_shared/blazor-guidelines/checklist.md` |
| Frontend core | `{{TOOLKIT_ROOT}}/skills/_shared/frontend-guidelines/frontend-practices.md` |
| FE structure (ARCH / CONTINUITY needs folder layout) | Prefer `{{TOOLKIT_ROOT}}/skills/_shared/frontend-guidelines/frontend-architecture.md` — **not** a per-framework CA tree |
| Markup / styles | `{{TOOLKIT_ROOT}}/skills/_shared/html-css-guidelines/` |
| .NET patterns | `{{TOOLKIT_ROOT}}/skills/_shared/dotnet-guidelines/csharp-patterns.md` |
| API rings (when Blazor + concentric .NET API) | `{{TOOLKIT_ROOT}}/skills/_shared/dotnet-guidelines/clean-architecture.md` — only if ARCH = concentric |
| Principles | `{{TOOLKIT_ROOT}}/skills/_shared/code-guidelines/principles/principles-cheatsheet.md` (+ `architecture-selection.md` or **one** approved style — never glob `architecture/**`) |
| Context | `{{TOOLKIT_ROOT}}/rules/context-management.mdc` |
| Subagent-first / SPAWN.md | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/subagent-first.md`, `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md` |
| Caveman Mode (if active) | `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md` |
| Reference index (routing only) | `{{TOOLKIT_ROOT}}/skills/blazor-developer/reference.md` |
| Process step detail (lazy) | `{{TOOLKIT_ROOT}}/skills/blazor-developer/references/<section>.md` |

**Never by default:** do not preload all `references/*.md`. do not preload the full `blazor-guidelines/` pack, all `html-css-guidelines/`, or every `dotnet-guidelines/` file. Load **one** Blazor topic file (or small set) when that surface is in scope. Do not dump full stack guideline packs or memory-bank. Load **one** section per Process step (`SKILL-REFERENCE-RETRIEVAL.md`).

**Progressive load:** `step-0-context` / DESIGN-BRIEF first; then fan-out to the matching Blazor row(s) only when implementing that concern.

## Reference routing

| Situation | Path |
|-----------|------|
| Scope / SDD escalation / design brief | `references/scope.md` |
| Implement flow | `references/execute-flow.md` |
| Must not (full) | `references/must-not.md` |

## Process

Read `references/<section>.md` for procedural detail — **not** full `reference.md`.

### Step -1b - Caveman Mode (Full cap)
1. Read `{{SDD_ROOT}}/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full" }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md`; apply **Full** participation cap + prefs `caveman_level` (Lite skills never escalate); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) during the session.
5. Auto-Clarity + never-compress gates/drafts/paths per `CAVEMAN.md`.

### 0. Scope
Follow `references/scope.md` (SDD escalation, design brief / host detection when present).

### 1. Execute
Follow `references/execute-flow.md` (subagent-first, workspace → guidelines → branch → implement → tests → handoff).

## Must not

Enforce the full list in `references/must-not.md`. Critical: no guideline dumps into children; no auto-commit; lazy-load stack guidelines only — never dump full packs or memory-bank.

## Handoff

| Situation | Next |
|-----------|------|
| Commit | `/commit` |
| Review | `/code-review` |
| Backend / API only | `/dotnet-developer` |
| Scope grew | `sdd-spec` -> `sdd-plan` -> `sdd-develop` |
| Missing design brief | `/impeccable shape` (new session) |
