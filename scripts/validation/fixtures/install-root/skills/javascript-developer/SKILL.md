---
name: javascript-developer
description: Implement or fix small-to-medium JavaScript/Node features without full SDD (Express/Fastify backend, DOM/html-css). Use for isolated JS/TS work or when invoking /javascript-developer.
---

## STOP - Read before ANY tool call

1. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/rules/guardrails.mdc`
2. Read `_shared/sdd-contracts/SESSION.md`; load session-state for `$Cwd`
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

## Trigger

Invoke when the user asks for: `/javascript-developer`, `js fix`, `node fix`, `implement Express/Fastify feature`, or for **small** JavaScript/TypeScript work that does not need a full PRD/PLAN cycle.

## Outcome

Working **JavaScript/TypeScript** code and tests in the open workspace: npm test/build (and project lint/type checks when configured) green, on a valid feature branch, with optional commit handoff. Covers **Node backend** (Express/Fastify; Nest recognized only) **and** existing DOM/`html-css` routes — Node backend is an extension, not a replacement. Does not replace SDD for multi-step or cross-repo features. There is **no** `node-developer` skill.

## When to prefer SDD instead

Recommend `/sdd-spec` -> `sdd-plan` -> `sdd-develop` if **two or more** apply:

| Signal | Indicator |
|--------|-----------|
| Layers | 3+ packages/layers (API, services, persistence, workers) across many modules |
| Database | New or altered schema / migrations |
| Repos | Backend and another repo or service |
| Integrations | New messaging, external APIs, or consumers |
| Size | 10+ files or estimated 4+ hours |
| PLAN exists | User already has an approved PLAN - use `sdd-develop` |

## DESIGN-BRIEF acceptance

If `docs/DESIGN-BRIEF.md` or `docs/design/DESIGN-BRIEF.md` exists with `target_stack: html-css`, treat it as the acceptance source. Map to DOM/vanilla or light libs; do **not** reinterpret visual decisions.

If the task is net-new UI without a brief, recommend `/impeccable shape` in a **new session** before implementing.

## Lazy-load (only when needed)

| When | Path (after `scripts/sync-cursor.ps1`) |
|------|----------------------------------------|
| Repo context | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/developer-common/step-0-context.md` |
| Before coding | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/developer-common/step-0.5-review-guidelines.md` |
| Branching | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/rules/branch-validation.mdc`, `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/developer-common/step-3-branching.md` |
| Pre-commit | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/developer-common/step-3.5-precommit-validation.md` |
| Commit / PR | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/developer-common/step-4-commits-pr.md`, `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/rules/conventional-commits.mdc` |
| Pre-PR gate | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/developer-common/step-7-checklist.md` |
| Node backend (Express/Fastify) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/javascript-guidelines/node-backend.md` |
| Architecture (greenfield / style unset) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/code-guidelines/principles/architecture-selection.md` — then **one** approved style only |
| Architecture (ARCH = concentric / clean / hexagonal) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/javascript-guidelines/architecture/concentric.md` (+ optional `principles/architecture/concentric-dependency.md`) |
| Architecture (ARCH = vertical-slice / VSA) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/javascript-guidelines/architecture/vertical-slice.md` (+ optional `principles/architecture/vertical-slice.md`) |
| Architecture (ARCH = event-driven / EDA) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/javascript-guidelines/architecture/event-driven.md` (+ optional `principles/architecture/event-driven.md`) |
| Node security | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/javascript-guidelines/node-security.md` |
| Node structure / errors | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/javascript-guidelines/node-structure-errors.md` |
| TypeScript strict | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/javascript-guidelines/typescript-strict.md` |
| Clean code TS / JS | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/javascript-guidelines/clean-code-ts.md`, `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/javascript-guidelines/clean-code-js.md` |
| Google TS style | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/javascript-guidelines/google-ts-style.md` |
| Frontend core (`html-css` / DOM work) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/frontend-guidelines/frontend-practices.md` |
| DOM patterns (`html-css` stack) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/javascript-guidelines/dom-patterns.md` |
| Semantic HTML (`html-css`) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/html-css-guidelines/semantic-html.md` |
| a11y basics (`html-css`) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/html-css-guidelines/accessibility-basics.md` |
| CSS foundations (`html-css`) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/html-css-guidelines/css-foundations.md` |
| Modern CSS (`html-css`) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/html-css-guidelines/modern-css.md` |
| SCSS (`html-css`) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/html-css-guidelines/scss-guidelines.md` |
| Inclusive components (`html-css`) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/html-css-guidelines/inclusive-components.md` |
| HTML/CSS checklist | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/html-css-guidelines/checklist.md` |
| Design brief | `docs/DESIGN-BRIEF.md` or `docs/design/DESIGN-BRIEF.md` |
| Subagent-first / SPAWN.md | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/developer-common/subagent-first.md`, `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/agents/SPAWN.md` |
| Caveman Mode (if active) | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/caveman/CAVEMAN.md` - **Full cap** |
| Context pressure | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/rules/context-management.mdc` |

Do **not** preload other stack guideline packs or corporate pipeline docs. Load only the `javascript-guidelines` (and frontend) rows needed for the current task. Preserve DOM/`html-css` paths when the task is UI — Node backend docs are additive. **MUST NOT** glob `architecture/**` — load **one** style overlay from ARCH/CONTINUITY (brownfield: discover-first if style omitted).

## Process

### Step -1b - Caveman Mode (Full cap)
1. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/sdd/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full" }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/caveman/CAVEMAN.md`; apply **Full** participation cap + prefs `caveman_level` (Lite skills never escalate); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) during the session.
5. Auto-Clarity + never-compress gates/drafts/paths per `CAVEMAN.md`.

### Subagent-first (before implement)

Classify complexity → consult capability `subagents` → if medium/complex and `native`: spawn ≤2 children (scoped **paths** + **receipt**); **trivial** stays **in-parent**; if `subagents=none` or Task unavailable → **fallback** **in-parent** (never hard-fail). Load `SPAWN.md` + `subagent-first.md`; do not paste guidelines into child prompts.

### 0. Workspace

Confirm Node/JS project (`package.json`, `tsconfig.json`, or JS/TS layout). Read `AGENTS.md` / `README.md`. Detect Express vs Fastify from dependencies; if Nest deps appear, recognize Nest and follow the existing Nest layout — **no** Nest skill and **no** `node-developer`. Summarize the user request and acceptance. Keep DOM/`html-css` routing when the task is frontend.

### 1. Guidelines (step 0.5)

Follow `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/developer-common/step-0.5-review-guidelines.md`: load only the guideline files needed for this task. For HTTP APIs load `node-backend.md`; for DOM/`html-css` load `dom-patterns.md` / frontend packs; load TypeScript/clean-code docs when applicable.

### 2. Branch (step 3)

Baseline branch from user or repo default. Create/checkout `feature/<slug>` or `feat/<id>` - never commit on `main` / `master` / `develop`.

### 3. Plan micro-steps

List 3-7 concrete tasks (files to touch, tests to add). Stay within one session when possible; checkpoint per `context-management.mdc` (>= 40% -> pause, offer `/commit`).

### 4. Implement

Match existing project patterns (Glob/Read similar modules first).

| Surface | Typical work |
|---------|----------------|
| Node API | Express routers / Fastify plugins, validation, services |
| Nest (recognition) | Follow existing Nest modules — no dedicated Nest pack |
| DOM / html-css | Vanilla or light libs per DESIGN-BRIEF |
| Shared TS/JS | Types, utils, scripts |

Apply the matching `javascript-guidelines` docs while writing - do not paste full bodies into chat.

### 5. Tests

Add or update tests for changed behavior. Prefer integration-style HTTP tests when the project already uses them; unit tests for isolated logic. Runners: Jest / Vitest / Mocha / `node:test` per project.

### 6. Build and test

```bash
npm test
npm run build
```

Add lint/type steps if configured. Fix failures within scope. Ask before running the full suite if the repo is very large.

### 7. Pre-commit (step 3.5) and handoff

Run `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/developer-common/step-3.5-precommit-validation.md` when appropriate. Offer `/commit` - do not commit automatically.

Before push/PR, run `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/skills/_shared/developer-common/step-7-checklist.md` and confirm Express/Fastify or DOM guidance used as needed.

### 8. SDD escalation

If scope grows during work, stop and recommend:

```
/sdd-spec - [feature description]
# then
/sdd-plan - PRD/...
# then
/sdd-develop - PLAN/... - Step 1
```

## Must not

- Paste guideline packs into child prompts (pass scoped **paths** + require **receipt** only)
- Spawn children for **trivial** work (keep **in-parent**)
- Hard-fail when capability `subagents` is `none` or Task is unavailable (use **fallback** **in-parent**)
- Create or route to a separate `node-developer` skill (Node backend stays here)
- Treat Nest as a default skill or guidelines pack (recognition only)
- Drop DOM/`html-css` support in favor of backend-only routing
- Nested `feature/base/...` branches; commit on default integration branches
- Speculative features outside stated acceptance (YAGNI)
- Auto-commit or auto-PR without user request
- Deprecated SDD skill aliases in handoff text - use `sdd-spec`, `sdd-plan`, `sdd-develop`, `commit` only

## Handoff

| Situation | Next |
|-----------|------|
| Commit | `/commit` |
| Review | `/code-review` |
| Large scope | `/sdd-spec` -> `sdd-plan` -> `sdd-develop` |
| Missing design brief | `/impeccable shape` (new session) |
| Next PLAN step | New chat -> `/sdd-develop - PLAN/... - Step N` |
