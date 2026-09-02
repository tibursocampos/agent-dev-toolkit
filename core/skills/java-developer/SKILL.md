---
name: java-developer
description: Implement or fix small-to-medium Java features without full SDD (Spring Boot default). Use for isolated JVM/Spring Boot work or when invoking /java-developer.
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

# Skill: java-developer

## Trigger

Invoke when the user asks for: `/java-developer`, `java fix`, `implement Spring Boot feature`, or for **small** JVM backend work that does not need a full PRD/PLAN cycle.

## Outcome

Working **Java** (Spring Boot by default) code and tests in the open workspace: build and tests green, on a valid feature branch, with optional commit handoff. Does not replace SDD for multi-step or cross-repo features.

## Lazy-load (only when needed)

| When | Path (after `scripts/sync-cursor.ps1`) |
|------|----------------------------------------|
| Repo context | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-0-context.md` |
| Before coding | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-0.5-review-guidelines.md` |
| Branching | `{{TOOLKIT_ROOT}}/rules/branch-validation.mdc`, `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-3-branching.md` |
| Pre-commit | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-3.5-precommit-validation.md` |
| Commit / PR | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-4-commits-pr.md`, `{{TOOLKIT_ROOT}}/rules/conventional-commits.mdc` |
| Pre-PR gate | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-7-checklist.md` |
| Spring Boot defaults | `{{TOOLKIT_ROOT}}/skills/_shared/java-guidelines/spring-boot-defaults.md` |
| Layers / packages | `{{TOOLKIT_ROOT}}/skills/_shared/java-guidelines/layered-structure.md` |
| Architecture boundaries | `{{TOOLKIT_ROOT}}/skills/_shared/java-guidelines/architecture-boundaries.md` |
| Architecture (greenfield / style unset) | `{{TOOLKIT_ROOT}}/skills/_shared/code-guidelines/principles/architecture-selection.md` — then **one** approved style only |
| Architecture (ARCH = concentric / clean / hexagonal) | `{{TOOLKIT_ROOT}}/skills/_shared/java-guidelines/architecture/clean-hexagonal.md` (+ optional `principles/architecture/concentric-dependency.md`) |
| Architecture (ARCH = vertical-slice / modulith) | `{{TOOLKIT_ROOT}}/skills/_shared/java-guidelines/architecture/modulith-vertical.md` (+ optional `principles/architecture/vertical-slice.md`) |
| Architecture (ARCH = ddd / tactical DDD) | `{{TOOLKIT_ROOT}}/skills/_shared/java-guidelines/architecture/ddd-tactical.md` (+ optional `principles/architecture/ddd-tactical.md`) |
| Architecture (ARCH = event-driven / EDA) | `{{TOOLKIT_ROOT}}/skills/_shared/java-guidelines/architecture/event-driven.md` (+ optional `principles/architecture/event-driven.md`) |
| Java style | `{{TOOLKIT_ROOT}}/skills/_shared/java-guidelines/java-style.md` |
| Build / BOM | `{{TOOLKIT_ROOT}}/skills/_shared/java-guidelines/build-and-bom.md` |
| Configuration | `{{TOOLKIT_ROOT}}/skills/_shared/java-guidelines/configuration.md` |
| Testing | `{{TOOLKIT_ROOT}}/skills/_shared/java-guidelines/testing.md` |
| Security basics | `{{TOOLKIT_ROOT}}/skills/_shared/java-guidelines/security-basics.md` |
| Final checklist | `{{TOOLKIT_ROOT}}/skills/_shared/java-guidelines/checklist.md` |
| Subagent-first / SPAWN.md | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/subagent-first.md`, `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md` |
| Caveman Mode (if active) | `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md` - **Full cap** |
| Context pressure | `{{TOOLKIT_ROOT}}/rules/context-management.mdc` |
| Reference index (routing only) | `{{TOOLKIT_ROOT}}/skills/java-developer/reference.md` |
| Process step detail (lazy) | `{{TOOLKIT_ROOT}}/skills/java-developer/references/<section>.md` |

Do **not** preload other stack guideline packs or corporate pipeline docs. Load only the `java-guidelines` rows needed for the current task. **MUST NOT** glob `architecture/**` — load **one** style overlay from ARCH/CONTINUITY (brownfield: discover-first if style omitted).

**Never by default:** do not preload all `references/*.md`. do not preload other stack guideline packs. Load only Java/Spring rows needed for the current task. Do not dump full stack guideline packs or memory-bank. Load **one** section per Process step (`SKILL-REFERENCE-RETRIEVAL.md`).

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
