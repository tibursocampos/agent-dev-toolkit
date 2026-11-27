---
name: adt-developer
description: Smart router for stack skills, or senior fullstack for ad-hoc scripts/HTML/automation. Use for generic development or when invoking /adt-developer.
---

## STOP - Read before ANY tool call

Read `_shared/skill-boilerplate.md` first. It holds the guardrails read, the session gate rule, the user `sim` rule, the one-step rule, the gate check, and the user chat language rule. The steps below are skill-specific only.

### Step -1b - Caveman Mode (Full cap)
1. Read `{{SDD_ROOT}}/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full" }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md`; apply **Full** participation cap + prefs `caveman_level` (Lite skills never escalate); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) during the session.
5. Auto-Clarity + never-compress gates/drafts/paths per `CAVEMAN.md`.

---

## Trigger
**Negative signal:** applies as defined in `_shared/skill-boilerplate.md`; the skill-specific signals are listed below.

Use when user asks for `/adt-developer` or requests generic coding/refactoring tasks without specifying a stack.

## Outcome

Correct stack skill loaded and executed, or ad-hoc implementation in fallback mode with optional handoff to `/adt-commit`.

## Lazy-load (only when needed)

| When | Path (after syncing the active adapter) |
|------|----------------------------------------|
| Structure / quality (when coding) | `{{TOOLKIT_ROOT}}/skills/_shared/code-guidelines/principles/structure-and-quality.md` |
| Git / language policy | `{{TOOLKIT_ROOT}}/rules/branch-validation.mdc` |
| Developer flow | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/GUIDE.md` |
| Subagent-first / SPAWN.md | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/subagent-first.md`, `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md` |
| Caveman Mode (if active) | `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md` |
| Reference index (routing only) | `{{TOOLKIT_ROOT}}/skills/adt-developer/reference.md` |
| Process step detail (lazy) | `{{TOOLKIT_ROOT}}/skills/adt-developer/references/<section>.md` |

Do **not** load `dev_persona` or Antigravity KI artifacts.

**Never by default:** do not preload all `references/*.md` or all stack guideline packs. Route first; load **one** section per Process step (`SKILL-REFERENCE-RETRIEVAL.md`).

## Reference routing

| Situation | Path |
|-----------|------|
| Frontend / design brief | `references/frontend-design-routing.md` |
| Stack match table | `references/stack-routing.md` |
| Fallback execution | `references/fallback-execution.md` |
| Must not (full) | `references/must-not.md` |

## Process

Read `references/<section>.md` for procedural detail — **not** full `reference.md`.

### 0. Frontend design routing
Follow `references/frontend-design-routing.md` for ad-hoc UI work. Explicit PLAN work first goes to its flow owner in Step 1.

### 1. Stack routing
If the request explicitly identifies a PLAN or a PLAN step, apply the PLAN routing in `references/stack-routing.md` first. The flow owner reads the approved PLAN and owns its progress. `REFINE/tasks.md` is optional context and is never a second progress ledger.

For requests without a PLAN, apply ordinary stack routing (e.g. `pom.xml` / `build.gradle` → `adt-java-developer`). On match, load that stack `SKILL.md` and stop this router.

### 2. Fallback only
If no stack match: follow `references/fallback-execution.md`.

## Must not

Enforce the full list in `references/must-not.md`. Critical: route before implement; no guideline dumps into children; no auto-commit.

## Handoff

| Situation | Next |
|-----------|------|
| Commit | `/adt-commit` |
| .NET work (explicit) | `/adt-dotnet-developer` |
| Java work (explicit) | `/adt-java-developer` |
| Large scope | `/adt-sdd-spec` -> `adt-sdd-plan` -> `adt-sdd-develop` |
| UI design / brief | For net-new UI or a substantial visual redesign, create or update `docs/DESIGN-BRIEF.md`; see `frontend-guidelines/frontend-practices.md`. |
| New Blip plugin scaffold | `/adt-blip-plugin-developer` |
