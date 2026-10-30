---
name: react-developer
description: Implement or fix small-to-medium React features without full SDD (hooks, TSX, RTL). Use for isolated React work or when invoking /react-developer.
---

## STOP - Read before ANY tool call

Read `_shared/skill-boilerplate.md` first. It holds the guardrails read, the session gate rule, the user `sim` rule, the one-step rule, the gate check, and the user chat language rule. The steps below are skill-specific only.

---

# Skill: react-developer

## Trigger
**Negative signal:** applies as defined in `_shared/skill-boilerplate.md`; the skill-specific signals are listed below.

Invoke when the user asks for: `/react-developer`, `react fix`, or **small** isolated React (web) work that does not need a full PRD/PLAN cycle.

## Outcome

Working React components and tests in the target workspace, validated with tests/build, on a valid feature branch, with optional `/commit` handoff. Does not replace SDD for multi-step or cross-repo features.

## Lazy-load (only when needed)

| When | Path (after syncing the active adapter) |
|------|----------------------------------------|
| Repo context | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-0-context.md` |
| Before coding | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-0.5-review-guidelines.md` |
| Structure / quality (when coding) | `{{TOOLKIT_ROOT}}/skills/_shared/code-guidelines/principles/structure-and-quality.md` |
| Branching | `{{TOOLKIT_ROOT}}/rules/branch-validation.mdc`, `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-3-branching.md` |
| Pre-commit | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-3.5-precommit-validation.md` |
| Commit / PR | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-4-commits-pr.md`, `{{TOOLKIT_ROOT}}/rules/conventional-commits.mdc` |
| Pre-PR gate | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-7-checklist.md` |
| Design brief | `docs/DESIGN-BRIEF.md` or `docs/design/DESIGN-BRIEF.md` |
| React components / state | `{{TOOLKIT_ROOT}}/skills/_shared/react-guidelines/components-and-state.md` |
| React hooks / effects | `{{TOOLKIT_ROOT}}/skills/_shared/react-guidelines/hooks-and-effects.md` |
| React testing (RTL) | `{{TOOLKIT_ROOT}}/skills/_shared/react-guidelines/testing.md` |
| React performance | `{{TOOLKIT_ROOT}}/skills/_shared/react-guidelines/performance.md` |
| React accessibility | `{{TOOLKIT_ROOT}}/skills/_shared/react-guidelines/accessibility.md` |
| React data fetching | `{{TOOLKIT_ROOT}}/skills/_shared/react-guidelines/data-fetching.md` |
| React delivery checklist | `{{TOOLKIT_ROOT}}/skills/_shared/react-guidelines/checklist.md` |
| Blip plugin (when `blip-ds` in `package.json`) | `{{TOOLKIT_ROOT}}/skills/_shared/blip-guidelines/` - load `plugin-architecture.md` always; add `auth-and-permissions.md` if multi-route/auth; add `external-api-integration.md` if calling REST backend |
| Frontend practices | `{{TOOLKIT_ROOT}}/skills/_shared/frontend-guidelines/frontend-practices.md` |
| FE structure (ARCH / CONTINUITY needs folder layout) | Prefer `{{TOOLKIT_ROOT}}/skills/_shared/frontend-guidelines/frontend-architecture.md` — **not** a per-framework CA tree |
| Markup / styles | `{{TOOLKIT_ROOT}}/skills/_shared/html-css-guidelines/` |
| Principles | `{{TOOLKIT_ROOT}}/skills/_shared/code-guidelines/principles/principles-cheatsheet.md` (+ `architecture-selection.md` or **one** approved style — never glob `architecture/**`) |
| Subagent-first / SPAWN.md | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/subagent-first.md`, `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md` |
| Caveman Mode (if active) | `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md` - **Full cap** |
| Reference index (routing only) | `{{TOOLKIT_ROOT}}/skills/react-developer/reference.md` |
| Process step detail (lazy) | `{{TOOLKIT_ROOT}}/skills/react-developer/references/<section>.md` |

Do **not** preload unrelated guideline trees. Do not redesign `react-guidelines/` in this skill — load existing pack rows only. For **mobile** React Native / Expo, route to `/react-native-developer` instead.

**Never by default:** do not preload all `references/*.md`. do not preload other stack guideline packs or full frontend trees. Load only rows needed for the current task. Do not dump full stack guideline packs or memory-bank. Load **one** section per Process step (`SKILL-REFERENCE-RETRIEVAL.md`).

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
| Scope grew | `/sdd-spec` -> `sdd-plan` -> `sdd-develop` |
| Missing design brief | Create a concise `docs/DESIGN-BRIEF.md` before substantial UI redesign work; see `frontend-guidelines/frontend-practices.md`. |
| Mobile / Expo | `/react-native-developer` |
