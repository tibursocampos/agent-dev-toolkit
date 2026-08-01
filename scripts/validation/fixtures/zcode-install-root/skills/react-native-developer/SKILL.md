---
name: react-native-developer
description: Implement or fix small-to-medium React Native / Expo features without full SDD (hooks, TSX, RNTL). Use for isolated React Native work or when invoking /react-native-developer.
---

## STOP - Read before ANY tool call

1. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/rules/guardrails.mdc`
2. Read `_shared/sdd-contracts/SESSION.md`; load session-state for `$Cwd`
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

## Trigger

Invoke when the user asks for: `/react-native-developer`, `react-native`, `expo`, or **small** isolated React Native / Expo work that does not need a full PRD/PLAN cycle.

## Outcome

Working React Native components and tests in the target workspace, validated with tests/build, on a valid feature branch, with optional `/commit` handoff. Does not replace SDD for multi-step or cross-repo features.

## When to prefer SDD instead

Recommend `/sdd-spec` -> `sdd-plan` -> `sdd-develop` if **two or more** apply:

| Signal | Indicator |
|--------|-----------|
| Layers | 3+ layers (screens, navigation, services, native modules) across many packages |
| API contracts | New or altered HTTP/API contracts shared across apps |
| Repos | Mobile app and another repo or service |
| Integrations | New native modules, push, deep links, or external SDKs |
| Size | 10+ files or estimated 4+ hours |
| PLAN exists | User already has an approved PLAN - use `sdd-develop` |

## DESIGN-BRIEF acceptance

If `docs/DESIGN-BRIEF.md` or `docs/design/DESIGN-BRIEF.md` exists, treat it as the acceptance source. Map sections to React Native / TSX; do **not** reinterpret visual decisions. Implement **one session scope** from section 10 only.

If the task is net-new UI without a brief, recommend `/impeccable shape` in a **new session** before implementing.

## Lazy-load (only when needed)

| When | Path (after `scripts/sync-cursor.ps1`) |
|------|----------------------------------------|
| Repo context | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/developer-common/step-0-context.md` |
| Before coding | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/developer-common/step-0.5-review-guidelines.md` |
| Branching | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/rules/branch-validation.mdc`, `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/developer-common/step-3-branching.md` |
| Pre-commit | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/developer-common/step-3.5-precommit-validation.md` |
| Commit / PR | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/developer-common/step-4-commits-pr.md`, `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/rules/conventional-commits.mdc` |
| Pre-PR gate | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/developer-common/step-7-checklist.md` |
| Design brief | `docs/DESIGN-BRIEF.md` or `docs/design/DESIGN-BRIEF.md` |
| RN structure / navigation | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/react-native-guidelines/structure-and-navigation.md` |
| RN styling / platform | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/react-native-guidelines/styling-and-platform.md` |
| RN lists / performance | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/react-native-guidelines/lists-and-performance.md` |
| RN testing (RNTL) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/react-native-guidelines/testing.md` |
| RN accessibility | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/react-native-guidelines/accessibility.md` |
| Expo config / env | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/react-native-guidelines/expo-config-and-env.md` |
| RN delivery checklist | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/react-native-guidelines/checklist.md` |
| Shared React hooks (optional) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/react-guidelines/hooks-and-effects.md`, `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/react-guidelines/components-and-state.md` — hooks/composition only; **not** primary mobile guidance |
| Frontend practices (optional) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/frontend-guidelines/frontend-practices.md` |
| FE structure (ARCH / CONTINUITY needs folder layout) | Prefer `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/frontend-guidelines/frontend-architecture.md` — **not** a per-framework CA tree |
| Principles | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/code-guidelines/principles/principles-cheatsheet.md` (+ `architecture-selection.md` or **one** approved style — never glob `architecture/**`) |
| Subagent-first / SPAWN.md | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/developer-common/subagent-first.md`, `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/agents/SPAWN.md` |
| Caveman Mode (if active) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/caveman/CAVEMAN.md` - **Full cap** |
| Context pressure | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/rules/context-management.mdc` |

**Primary mobile pack:** `react-native-guidelines/`. Do **not** depend only on `react-guidelines/` for navigation, StyleSheet, platform, or RNTL. Do **not** load `blip-guidelines/` (Blip plugins are web React). Do not preload unrelated guideline trees.

## Process

### Step -1b - Caveman Mode (Full cap)
1. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/sdd/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full" }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/zcode-install-root/skills/_shared/caveman/CAVEMAN.md`; apply **Full** participation cap + prefs `caveman_level` (Lite skills never escalate); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) during the session.
5. Auto-Clarity + never-compress gates/drafts/paths per `CAVEMAN.md`.

### Subagent-first (before implement)

Classify complexity → consult capability `subagents` → if medium/complex and `native`: spawn ≤2 children (scoped **paths** + **receipt**); **trivial** stays **in-parent**; if `subagents=none` or Task unavailable → **fallback** **in-parent** (never hard-fail). Load `SPAWN.md` + `subagent-first.md`; do not paste guidelines into child prompts.

### 0. Workspace

Confirm React Native / Expo project (`package.json` with `react-native` and/or `expo`; often `app.json` / `app.config.*`). Follow `step-0-context.md`. Summarize acceptance.

### 1. Guidelines (step 0.5)

Follow `step-0.5-review-guidelines.md`: load `react-native-guidelines/` files needed for this task first (`structure-and-navigation.md`, `testing.md`, `checklist.md`, plus styling/lists/a11y/expo-config as relevant). Optionally load shared `react-guidelines/` for hooks/composition only.

### 2. Branch (step 3)

Baseline from user or repo default. Create/checkout `feature/<slug>` or `feat/<id>` — never commit on `main` / `master` / `develop`.

### 3. Plan micro-steps

List 3-7 concrete tasks; checkpoint per `context-management.mdc` (>= 40% -> pause, offer `/commit`).

### 4. Implement

Functional components, hooks, clean React Native architecture. Match existing patterns (Expo Router / React Navigation, StyleSheet, platform splits). Apply `react-native-guidelines/` while writing — do not paste full bodies into chat.

### 5. Tests

Jest + React Native Testing Library (or project equivalents) for changed behavior. Prefer `testing.md` guidance.

### 6. Build and test

```bash
npm test
```

(or project-equivalent scripts such as `yarn test`, `expo` lint/typecheck, or CI scripts from `package.json`)

### 7. Pre-commit (step 3.5) and handoff

Run `step-3.5-precommit-validation.md` when appropriate. Offer `/commit` — do not commit automatically. Before push/PR, run `step-7-checklist.md` and `react-native-guidelines/checklist.md`.

## Must not

- Paste guideline packs into child prompts (pass scoped **paths** + require **receipt** only)
- Spawn children for **trivial** work (keep **in-parent**)
- Hard-fail when capability `subagents` is `none` or Task is unavailable (use **fallback** **in-parent**)
- Rely only on `react-guidelines/` for mobile navigation / StyleSheet / platform / RNTL
- Auto-commit or auto-PR
- Leave AI traces in code or identifiers
- Load Blip / web-only plugin guidelines
- Use obsolete corporate pipeline docs

## Handoff

| Situation | Next |
|-----------|------|
| Commit | `/commit` |
| Review | `/code-review` |
| Scope grew | `/sdd-spec` -> `sdd-plan` -> `sdd-develop` |
| Missing design brief | `/impeccable shape` (new session) |
| Web React | `/react-developer` |
