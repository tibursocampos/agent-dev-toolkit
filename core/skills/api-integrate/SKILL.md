---
name: api-integrate
description: Generate typed API clients and DTOs from OpenAPI/Swagger. Use when integrating an API or invoking /api-integrate.
---

## STOP - Read before ANY tool call

Read `_shared/skill-boilerplate.md` first. It holds the guardrails read, the session gate rule, the user `sim` rule, the one-step rule, the gate check, and the user chat language rule. The steps below are skill-specific only.

---

# Skill: api-integrate

## Trigger
**Negative signal:** applies as defined in `_shared/skill-boilerplate.md`; the skill-specific signals are listed below.

Invoke when the user requests: `/api-integrate`, `integrate api`, `/api-integrate`, or asks to integrate endpoints from a schema.

**Arguments (optional):**

| Input | Meaning |
|-------|---------|
| Schema source | Path to local `openapi.json` / `swagger.yaml` or a remote metadata URL |
| Target service name | Specific name for the generated client class / wrapper |

## Outcome

A typed, modular, and robust API client containing:

1. Strongly typed DTO models (Request and Response contracts).
2. Clean service wrapper or client declarations using preferred libraries (e.g., Refit/HttpClient for C#, Axios/Fetch for TS/JS, HTTPX for Python).
3. Configured authentication headers, timeout limits, and robust network error wrappers.

## Lazy-load (only when needed)

| When | Path (after syncing the active adapter) |
|------|----------------------------------------|
| C# projects | `{{TOOLKIT_ROOT}}/skills/_shared/dotnet-guidelines/clean-architecture.md`, `{{TOOLKIT_ROOT}}/skills/_shared/dotnet-guidelines/csharp-patterns.md` |
| .NET tests (when adding tests) | `{{TOOLKIT_ROOT}}/skills/_shared/dotnet-guidelines/dotnet-test-patterns.md` |
| JavaScript / TypeScript | `{{TOOLKIT_ROOT}}/skills/_shared/javascript-guidelines/clean-code-ts.md`, `{{TOOLKIT_ROOT}}/skills/_shared/javascript-guidelines/google-ts-style.md` |
| Python projects | `{{TOOLKIT_ROOT}}/skills/_shared/python-guidelines/google-style.md` |
| Caveman Mode (if active) | `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md` - **Full cap** |
| Reference index (routing only) | `{{TOOLKIT_ROOT}}/skills/api-integrate/reference.md` |
| Process step detail (lazy) | `{{TOOLKIT_ROOT}}/skills/api-integrate/references/<section>.md` |

**Never by default:** do not preload all `references/*.md`, unrelated stack guidelines, or full OpenAPI dumps. Load **one** section per Process step (`SKILL-REFERENCE-RETRIEVAL.md`).

## Reference routing

| Situation | Path |
|-----------|------|
| Schema / plan / workflow | `references/schema-plan.md` |
| Generate client / DTOs | `references/generate-client.md` |
| Validate / handoff | `references/validate-handoff.md` |
| Must not (full) | `references/must-not.md` |

## Process

Read `references/<section>.md` for procedural detail — **not** full `reference.md`.

### Step -1b - Caveman Mode (Full cap)
1. Read `{{SDD_ROOT}}/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full" }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md`; apply **Full** participation cap + prefs `caveman_level` (Lite skills never escalate); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) during the session.
5. Auto-Clarity + never-compress gates/drafts/paths per `CAVEMAN.md`.

### -1. Re-check guardrails and session

Confirm `guardrails.mdc` and `SESSION.md` are loaded. If missing, ask in the user chat language before continuing.

### 0–1. Schema and plan
Follow `references/schema-plan.md`. Wait for workflow choice.

### 2–4. Generate client
Follow `references/generate-client.md`.

### 5–6. Validate and handoff
Follow `references/validate-handoff.md`.

## Must not

Enforce the full list in `references/must-not.md`. Critical: no `any` DTOs; no hardcoded secrets; standards packing is out of scope (use `api-standards`).
