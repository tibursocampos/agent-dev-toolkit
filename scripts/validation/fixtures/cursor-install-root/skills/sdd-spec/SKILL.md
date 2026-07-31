---
name: sdd-spec
description: Create a PRD for a new feature or change (agent PRD .md, pt-BR default under features/). Feeds sdd-plan. Use when creating a spec or invoking /sdd-spec.
---

## STOP - Read before ANY tool call

1. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/rules/guardrails.mdc`
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

# Skill: sdd-spec

## Trigger

Invoke when the user asks for: `/sdd-spec`, `create spec`, `new feature`.

## Outcome

A complete **PRD** (agent `.md` artifact) in **Brazilian Portuguese (pt-BR)** at a **canonical** path under `features/NNN-slug/USnn/PRD/` (Forma A default story `US01`; or `TSnn`). Global: `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/sdd/<repo-id>/features/...`. Root/flat `PRD/` is **not** a valid Classic SDD path. English only if the user overrides in this invocation. Mandatory input for **sdd-plan**.

## PRD boundaries

The PRD answers **what**, not **how**. No implementation code. Identifiers (types, APIs, paths) in **English**.

## Lazy-load (only when needed)

| When | Path (after sync) |
|------|-------------------|
| Pipeline guards, modes, confirm, paths | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/skills/_shared/sdd-artifacts/PIPELINE.md` |
| Storage, manifest, `.gitignore` | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/skills/_shared/sdd-artifacts/STORAGE.md` |
| Caveman Mode (if active) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/skills/_shared/caveman/CAVEMAN.md` - **Lite cap** |
| SDD artifact language | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/rules/sdd-artifact-language-pt-br.mdc` |
| .NET / C# context | `dotnet-guidelines/clean-architecture.md`, `csharp-patterns.md` |
| Context pressure | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/rules/context-management.mdc` |

## Process

### Step -1b - Caveman Mode (Lite cap)
1. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/sdd/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full" }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/skills/_shared/caveman/CAVEMAN.md`; apply **Lite** participation cap + prefs `caveman_level` (Lite skills never escalate); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) during the session.
5. Auto-Clarity + never-compress gates/drafts/paths per `CAVEMAN.md`.

### -1. Pipeline and mode

Load `STORAGE.md` and `PIPELINE.md`. Use `STORAGE.md` schema v2 and run the dynamic storage resolution algorithm with parameter `$Workflow = classic`. Resolve `storage_mode` and `path` for the active repository. If this is the first run for the repository, execute the storage mode selection flow and persist it in `manifest.json`.
Apply Phase A/B: in Plan/Ask, draft in chat only until Agent + user **sim** on section Confirm below. Pipeline lock: no PLAN, no `Edit`/`Write` on `*.cs`, `*.csproj`, migrations.

### 0. Workspace

Target repo (not this toolkit repo unless subject). Read `AGENTS.md` / `README.md`. Detect stack. Resolve `<repo-id>` and classic feature root (`STORAGE.md`). Glob PRDs under `features/**/PRD/` only (workspace + global feature root) for `NNN`. Forma A default story folder = `US01` when unspecified.

### 1. Requirements

**Prior context** (chat, code-review, backlog, **feature siblings**): structured summary + max **3** gap questions - skip full questionnaire (`PIPELINE.md` section Prior context + Feature / story siblings). When under `features/NNN-slug/`, load `FEATURE.md`, `CONTINUITY.md`, and story `STORY.md` / optional `REFINE|ANALYSIS|ARCH|SEC` before asking.

**Otherwise** ask (pt-BR):

```
Vou criar o PRD. Informe:
1) Feature - o que construir ou alterar?
2) Comportamento atual
3) Comportamento esperado
4) Contexto adicional (opcional)
5) ID de rastreamento (opcional)
```

Wait for answers.

### 2-5. Confirm repo, explore code, clarify (<=5), technical analysis

Per existing skill intent: branch confirmation, Glob/Grep/Read, brief impact/risks for the PRD.

### 6. Context checkpoint

`context-management.mdc`. At >=40%, draft in chat or partial file; warn before continuing.

### 6.75 Confirm before write

Show title, `NNN`, **full canonical path** (resolved under the active storage-mode directory), storage mode, bullets, and status **Pronto para planejamento**. Wait for **sim** / **ajustar** / **cancelar**. In Plan/Ask without **sim** in Agent: Phase A message only.

Record `artifact_language` (default pt-BR) from manifest or user override.

### 7. Write PRD (Agent + sim only)

1. Validate path per `PIPELINE.md` section Path validation - abort if non-canonical (**writes** only under `features/.../PRD/`).
2. Repository mode: `.gitignore` per `STORAGE.md` (include `/features/`; keep `/PRD/` `/PLAN/` as safety net only; **do not** add `/memory-bank/` — commit bank when product knowledge; never commit secrets). Global mode: do **not** edit `.gitignore`.
3. Path: `features/NNN-slug/US01/PRD/NNN_short_feature_slug.md` (adjust story id); body from `reference.md`.
4. Product `docs/` in scope: ask doc language first.

Report path, storage, language, `.gitignore` changes. Handoff with **full** feature path:

```
/sdd-plan - features/NNN-slug/US01/PRD/NNN_short_feature_slug.md
```

## Must not

- English PRD body by default; implementation code in PRD
- `Write` outside canonical feature PRD folders (never root/flat `PRD/`); skip confirm-before-write
- `Edit`/`Write` production or test code; create PLAN in this session
- Claim "PRD saved" without successful `Write`
- External trackers; paste full guideline bodies into PRD

## Handoff

```
/sdd-plan - <full-prd-path-under-features>
```
