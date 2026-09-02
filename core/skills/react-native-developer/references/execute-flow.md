# react-native-developer — execute flow

Read this file for procedural detail. Do not dump stack guideline packs into chat or child prompts — lazy-load **one** guideline file when that surface is in scope.

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
