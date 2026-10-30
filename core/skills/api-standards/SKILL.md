---
name: api-standards
description: Apply agnostic HTTP/API design standards (REST shape, versioning, errors, naming) without company contracts. Use when designing or reviewing APIs or invoking /api-standards.
---

## STOP - Read before ANY tool call

Read `_shared/skill-boilerplate.md` first. It holds the guardrails read, the session gate rule, the user `sim` rule, the one-step rule, the gate check, and the user chat language rule. The steps below are skill-specific only.

---

# Skill: api-standards

## Trigger
**Negative signal:** applies as defined in `_shared/skill-boilerplate.md`; the skill-specific signals are listed below.

Invoke when the user requests: `/api-standards`, `api standards`, `REST conventions`, or asks for agnostic HTTP/API design guidance (not typed client generation).

**Arguments (optional):**

| Input | Meaning |
|-------|---------|
| Focus area | `rest` \| `versioning` \| `errors` \| `naming` \| `security` — load only that playbook |
| Artifact path | Existing OpenAPI / route map / controller folder to review against standards |

## Outcome

Agnostic API design guidance applied to the current workspace or design discussion:

1. Clear HTTP/REST shape recommendations (methods, status codes, resource URLs).
2. Versioning, error envelope, pagination, and naming conventions without vendor or company branding.
3. Security hygiene checklist that never embeds live secrets or proprietary contracts.
4. Handoff to `api-integrate` when the user needs OpenAPI → typed clients (out of scope here).

## Lazy-load (only when needed)

| When | Path (after syncing the active adapter) |
|------|----------------------------------------|
| Command playbook (step discovery after gates) | `{{TOOLKIT_ROOT}}/skills/api-standards/references/command.md` |
| Caveman Mode (if active) | `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md` - **Full cap** |
| Selective retrieval | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/SELECTIVE-RETRIEVAL.md` |
| Reference index (routing only) | `{{TOOLKIT_ROOT}}/skills/api-standards/reference.md` |
| Process step detail (lazy) | `{{TOOLKIT_ROOT}}/skills/api-standards/references/<section>.md` |

**Never by default:** do not preload all `references/*.md`, full OpenAPI dumps, `memory-bank/`, or PRD bodies. Do not load `api-integrate` playbooks unless handing off client generation. Load **one** `references/<section>.md` per Process step (`SKILL-REFERENCE-RETRIEVAL.md`).

## Reference routing

| Situation | Path |
|-----------|------|
| Step discovery after gates | `references/command.md` |
| REST / HTTP shape | `references/rest-http.md` |
| Versioning | `references/versioning.md` |
| Errors and pagination | `references/errors-pagination.md` |
| Naming and resource contracts | `references/naming-contracts.md` |
| Security (agnostic) | `references/security-agnostic.md` |
| Must not (full) | `references/must-not.md` |

## Process

After gates: **Read `references/command.md`** for ordered step discovery. Then load **one** `references/<section>.md` per step — **not** full `reference.md`.

### Step -1b - Caveman Mode (Full cap)
1. Read `{{SDD_ROOT}}/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full" }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md`; apply **Full** participation cap + prefs `caveman_level` (Lite skills never escalate); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) during the session.
5. Auto-Clarity + never-compress gates/drafts/paths per `CAVEMAN.md`.

### -1. Re-check guardrails and session

Confirm `guardrails.mdc` and `SESSION.md` are loaded. If missing, ask in the **user chat language** before continuing.

### 0. Scope and focus

* Confirm the ask is **standards / design review**, not typed client generation (that is `api-integrate`).
* If the user named a focus area, load only that playbook; otherwise ask once which areas matter (max three).
* Apply selective retrieval: paths + short excerpts only.

### 1. Inspect current surface (optional)

* If an artifact path exists, skim routes / OpenAPI / controllers for gaps vs loaded standards.
* Do not rewrite large APIs in one pass — prefer a short gap list with severity.

### 2. Apply standards

* Load the matching `references/*.md` section(s) one at a time.
* Produce agnostic recommendations (English identifiers; chat language for prose).
* Never invent company-specific product names, internal contract ids, or branded error codes.

### 3. Report and handoff

* Summarize recommendations and open questions.
* For OpenAPI → clients/DTOs: hand off to `api-integrate`.
* Offer `/commit` only if files were changed in the consumer repo.

## Must not

* Embed company, vendor, or product-specific API contracts, naming schemes, or branding.
* Generate typed API clients / DTOs (use `api-integrate`).
* Hardcode credentials, tokens, base URLs with secrets, or unretracted `.env` values.
* Dump entire `memory-bank/` or paste full PRD/OpenAPI into the session (`SELECTIVE-RETRIEVAL.md`).
* Pretend this skill replaces stack `*-developer` implementation work.

## Handoff

```
api-integrate - <openapi-or-schema-path>
```

Or continue with the stack skill for implementation after standards are agreed.
