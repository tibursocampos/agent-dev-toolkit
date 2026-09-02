---
name: react-native-developer
description: Implement or fix small-to-medium React Native / Expo features without full SDD (hooks, TSX, RNTL). Use for isolated React Native work or when invoking /react-native-developer.
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

# Skill: react-native-developer

## Trigger

Invoke when the user asks for: `/react-native-developer`, `react-native`, `expo`, or **small** isolated React Native / Expo work that does not need a full PRD/PLAN cycle.

## Outcome

Working React Native components and tests in the target workspace, validated with tests/build, on a valid feature branch, with optional `/commit` handoff. Does not replace SDD for multi-step or cross-repo features.

## Lazy-load (only when needed)

| When | Path (after `scripts/sync-cursor.ps1`) |
|------|----------------------------------------|
| Repo context | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-0-context.md` |
| Before coding | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-0.5-review-guidelines.md` |
| Branching | `{{TOOLKIT_ROOT}}/rules/branch-validation.mdc`, `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-3-branching.md` |
| Pre-commit | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-3.5-precommit-validation.md` |
| Commit / PR | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-4-commits-pr.md`, `{{TOOLKIT_ROOT}}/rules/conventional-commits.mdc` |
| Pre-PR gate | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-7-checklist.md` |
| Design brief | `docs/DESIGN-BRIEF.md` or `docs/design/DESIGN-BRIEF.md` |
| RN structure / navigation | `{{TOOLKIT_ROOT}}/skills/_shared/react-native-guidelines/structure-and-navigation.md` |
| RN styling / platform | `{{TOOLKIT_ROOT}}/skills/_shared/react-native-guidelines/styling-and-platform.md` |
| RN lists / performance | `{{TOOLKIT_ROOT}}/skills/_shared/react-native-guidelines/lists-and-performance.md` |
| RN testing (RNTL) | `{{TOOLKIT_ROOT}}/skills/_shared/react-native-guidelines/testing.md` |
| RN accessibility | `{{TOOLKIT_ROOT}}/skills/_shared/react-native-guidelines/accessibility.md` |
| Expo config / env | `{{TOOLKIT_ROOT}}/skills/_shared/react-native-guidelines/expo-config-and-env.md` |
| RN delivery checklist | `{{TOOLKIT_ROOT}}/skills/_shared/react-native-guidelines/checklist.md` |
| Shared React hooks (optional) | `{{TOOLKIT_ROOT}}/skills/_shared/react-guidelines/hooks-and-effects.md`, `{{TOOLKIT_ROOT}}/skills/_shared/react-guidelines/components-and-state.md` — hooks/composition only; **not** primary mobile guidance |
| Frontend practices (optional) | `{{TOOLKIT_ROOT}}/skills/_shared/frontend-guidelines/frontend-practices.md` |
| FE structure (ARCH / CONTINUITY needs folder layout) | Prefer `{{TOOLKIT_ROOT}}/skills/_shared/frontend-guidelines/frontend-architecture.md` — **not** a per-framework CA tree |
| Principles | `{{TOOLKIT_ROOT}}/skills/_shared/code-guidelines/principles/principles-cheatsheet.md` (+ `architecture-selection.md` or **one** approved style — never glob `architecture/**`) |
| Subagent-first / SPAWN.md | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/subagent-first.md`, `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md` |
| Caveman Mode (if active) | `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md` - **Full cap** |
| Context pressure | `{{TOOLKIT_ROOT}}/rules/context-management.mdc` |
| Reference index (routing only) | `{{TOOLKIT_ROOT}}/skills/react-native-developer/reference.md` |
| Process step detail (lazy) | `{{TOOLKIT_ROOT}}/skills/react-native-developer/references/<section>.md` |

**Primary mobile pack:** `react-native-guidelines/`. Do **not** depend only on `react-guidelines/` for navigation, StyleSheet, platform, or RNTL. Do **not** load `blip-guidelines/` (Blip plugins are web React). Do not preload unrelated guideline trees.

**Never by default:** do not preload all `references/*.md`. do not preload other stack guideline packs. Load only rows needed for the current task. Do not dump full stack guideline packs or memory-bank. Load **one** section per Process step (`SKILL-REFERENCE-RETRIEVAL.md`).

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
| Missing design brief | `/impeccable shape` (new session) |
| Web React | `/react-developer` |
