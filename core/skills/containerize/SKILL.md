---
name: containerize
description: Write multi-stage Dockerfiles, .dockerignore, and docker-compose for local dev. Use when dockerizing a project or invoking /containerize.
---


## STOP - Read before ANY tool call

1. Read `{{GUARDRAILS_PATH}}`
2. Read `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/SESSION.md`; load session-state for `$Cwd`
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

# Skill: containerize

## Trigger

Invoke when the user requests: `/containerize`, `dockerize project`, `/containerize`, or asks to containerize the workspace.

**Arguments (optional):**

| Input | Meaning |
|-------|---------|
| Runtime port | The primary network port to expose in the container |

## Outcome

A set of production-ready container configurations:

1. **Dockerfile:** Multi-stage build leveraging minimal base images (alpine or distroless), strict layer caching, and non-root execution.
2. **.dockerignore:** Clean file excluding local packages, builds, git, and sensitive secrets.
3. **docker-compose.yml:** Orchestrated configuration for local testing, binding the application port and spinning up required database/caching services.

## Lazy-load (only when needed)

| When | Path (after `scripts/sync-cursor.ps1`) |
|------|----------------------------------------|
| DevOps context | `{{TOOLKIT_ROOT}}/skills/_shared/devops-guidelines/deployment-process.md` |
| Caveman Mode (if active) | `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md` - **Full cap** |
| Reference index (routing only) | `{{TOOLKIT_ROOT}}/skills/containerize/reference.md` |
| Process step detail (lazy) | `{{TOOLKIT_ROOT}}/skills/containerize/references/<section>.md` |

**Never by default:** do not preload all `references/*.md`, unrelated developer guidelines, or full Docker docs. Load **one** section per Process step (`SKILL-REFERENCE-RETRIEVAL.md`).

## Reference routing

| Situation | Path |
|-----------|------|
| Workspace inspect | `references/workspace-inspect.md` |
| Workflow decision | `references/workflow-decision.md` |
| Generate files | `references/generate-files.md` |
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

Confirm `guardrails.mdc` and `SESSION.md` are loaded. If missing, ask (pt-BR) before continuing.

### 0–1. Inspect and decide workflow
Follow `references/workspace-inspect.md`, then `references/workflow-decision.md`. Wait for explicit choice.

### 2–4. Generate files
Follow `references/generate-files.md`.

### 5–6. Validate and handoff
Follow `references/validate-handoff.md`.

## Must not

Enforce the full list in `references/must-not.md`. Critical: no unretracted secrets in checked-in files; prefer alpine/distroless runtimes.
