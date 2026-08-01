---
name: api-integrate
description: Generate typed API clients and DTOs from OpenAPI/Swagger. Use when integrating an API or invoking /api-integrate.
---


## STOP - Read before ANY tool call

1. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/rules/guardrails.mdc`
2. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/sdd-artifacts/SESSION.md`; load session-state for `$Cwd`
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

# Skill: api-integrate

## Trigger

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

## Lazy-load

| When | Path (after `scripts/sync-cursor.ps1`) |
|------|----------------------------------------|
| C# projects | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/dotnet-guidelines/clean-architecture.md`, `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/dotnet-guidelines/csharp-patterns.md` |
| JavaScript / TypeScript | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/javascript-guidelines/clean-code-ts.md`, `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/javascript-guidelines/google-ts-style.md` |
| Python projects | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/python-guidelines/google-style.md` |
| Caveman Mode (if active) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/caveman/CAVEMAN.md` - **Full cap** |

## Process

### Step -1b - Caveman Mode (Full cap)
1. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/sdd/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full" }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/caveman/CAVEMAN.md`; apply **Full** participation cap + prefs `caveman_level` (Lite skills never escalate); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) during the session.
5. Auto-Clarity + never-compress gates/drafts/paths per `CAVEMAN.md`.

### -1. Re-check guardrails and session

Confirm `guardrails.mdc` and `SESSION.md` are loaded.
If missing, ask user (pt-BR):

```text
Antes da integracao de API, confirme:
- guardrails.mdc lido
- SESSION.md carregado

Posso seguir? (sim / ajustar / cancelar)
```


### 0. Detect Tech Stack and Locate Schema

* Identify target project language and preferred HTTP client patterns.
* Locate the OpenAPI spec (ask user or load the specified file path). Validate that the file is readable.

### 1. Plan Structure & Workflow Decision

* Propose the client layout:
  * Destination folder (e.g. `src/services/` or `Infrastructure/Clients/`).
  * File splits: client interface, models, configuration.
* Present the summary of identified API endpoints, routes, and request/response shapes.
* Stop and ask the user to choose the workflow execution path based on the integration scope:
  * **Option A - Direct Developer Skill (`/developer`):** For straightforward local client generation.
  * **Option B - Classic SDD (`/sdd-spec` -> `sdd-plan` -> `sdd-develop`):** For complex third-party integrations requiring formal specifications (PRD) and a detailed plan (PLAN) in Portuguese.
  * **Option D - Plain Chat Plan:** Establish a simple task list directly in the chat, executing steps one by one without extra file creations.
* **Wait for explicit user choice** before writing code or initializing another workflow.

### 2. DTO and Model Generation

* Parse request/response components in the OpenAPI schema.
* Generate strictly typed models:
  * TypeScript: `export interface UserDto { ... }`
  * C#: `public record UserDto(int Id, string Name);`
  * Python: `from pydantic import BaseModel` dataclasses or standard models.

### 3. API Method Implementation

* Generate the client wrapper calling the endpoints.
* Include JSDoc / C# XML documentation on each method indicating summary, parameter descriptions, and return types from the schema.
* Set up standard header injection (Authorization Bearer, API Keys).

### 4. Robust Error Handling

* Add interceptors or try/catch blocks that convert HTTP 4xx/5xx responses into meaningful custom exception structures.
* Avoid general exception swallowing.

### 5. Validate & Compile

* Save generated files.
* Execute local compile tasks (`dotnet build`, `tsc --noEmit`, `mypy`) to verify zero type mismatches or syntax issues.
* Suggest writing integration tests.

### 6. Handoff

* Offer committing the new files:

```
/commit
```

## Must not

* Generate generic `any` types for request/response payloads.
* Hardcode credentials, base URLs, or secret tokens. Fetch them from configuration environments.
