---
name: dotnet-developer
description: Implement or fix small-to-medium .NET features without full SDD (Clean Architecture, xUnit). Use for isolated C# work or when invoking /dotnet-developer.
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

# Skill: dotnet-developer

## Trigger

Invoke when the user asks for: `/dotnet-developer`, `dotnet fix`, `implement .NET feature`, or for **small** backend work that does not need a full PRD/PLAN cycle.

## Outcome

Working **.NET** code and tests in the open workspace: build and tests green, on a valid feature branch, with optional commit handoff. Does not replace SDD for multi-step or cross-repo features.

## Lazy-load (only when needed)

| When | Path (after `scripts/sync-cursor.ps1`) |
|------|----------------------------------------|
| Repo context | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-0-context.md` |
| Before coding | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-0.5-review-guidelines.md` |
| Branching | `{{TOOLKIT_ROOT}}/rules/branch-validation.mdc`, `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-3-branching.md` |
| Pre-commit | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-3.5-precommit-validation.md` |
| Commit / PR | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-4-commits-pr.md`, `{{TOOLKIT_ROOT}}/rules/conventional-commits.mdc` |
| Pre-PR gate | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-7-checklist.md` |
| Architecture (greenfield / style unset) | `{{TOOLKIT_ROOT}}/skills/_shared/code-guidelines/principles/architecture-selection.md` — then **one** approved style only |
| Architecture (ARCH = concentric / CA / onion / hexagonal) | `{{TOOLKIT_ROOT}}/skills/_shared/dotnet-guidelines/clean-architecture.md` (+ optional `principles/architecture/concentric-dependency.md`) |
| Architecture (ARCH = vertical-slice / VSA) | `{{TOOLKIT_ROOT}}/skills/_shared/dotnet-guidelines/vertical-slice.md` (+ optional `principles/architecture/vertical-slice.md`) |
| Architecture (ARCH = ddd / tactical DDD) | `{{TOOLKIT_ROOT}}/skills/_shared/dotnet-guidelines/ddd-tactical.md` (+ optional `principles/architecture/ddd-tactical.md`) |
| Architecture (ARCH = event-driven / EDA) | `{{TOOLKIT_ROOT}}/skills/_shared/dotnet-guidelines/event-driven.md` (+ optional `principles/architecture/event-driven.md`) |
| C# / tests | `{{TOOLKIT_ROOT}}/skills/_shared/dotnet-guidelines/csharp-patterns.md` |
| Subagent-first / SPAWN.md | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/subagent-first.md`, `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md` |
| Caveman Mode (if active) | `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md` - **Full cap** |
| Final checklist | `{{TOOLKIT_ROOT}}/skills/_shared/dotnet-guidelines/checklist.md` |
| Context pressure | `{{TOOLKIT_ROOT}}/rules/context-management.mdc` |
| Reference index (routing only) | `{{TOOLKIT_ROOT}}/skills/dotnet-developer/reference.md` |
| Process step detail (lazy) | `{{TOOLKIT_ROOT}}/skills/dotnet-developer/references/<section>.md` |

**Never by default:** do not preload all `references/*.md`. do not preload all `dotnet-guidelines/` files, all `developer-common/step-*.md`, or `code-guidelines/languages/**` / corporate pipeline docs. **MUST NOT** glob `architecture/**` — load **one** style overlay from ARCH/CONTINUITY (brownfield: discover-first if style omitted). Do not dump full stack guideline packs or memory-bank. Load **one** section per Process step (`SKILL-REFERENCE-RETRIEVAL.md`).

**Progressive load:** `step-0-context.md` first; then `step-0.5-review-guidelines.md` as the index for which packs to open; fan-out to individual `step-3*` / `step-4` / `step-7` only when that process step runs. For architecture: selection/contract (`architecture-selection.md` or ARCH) → **one** `dotnet-guidelines/` overlay → `csharp-patterns.md` / checklist only when coding or pre-PR.

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
| Large scope | `/sdd-spec` -> `sdd-plan` -> `sdd-develop` |
| Next PLAN step | New chat -> `/sdd-develop - PLAN/... - Step N` |
