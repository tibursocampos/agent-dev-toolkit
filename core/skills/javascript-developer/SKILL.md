---
name: javascript-developer
description: Implement or fix small-to-medium JavaScript/Node features without full SDD (Express/Fastify backend, DOM/html-css). Use for isolated JS/TS work or when invoking /javascript-developer.
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

# Skill: javascript-developer

## Trigger

Invoke when the user asks for: `/javascript-developer`, `js fix`, `node fix`, `implement Express/Fastify feature`, or for **small** JavaScript/TypeScript work that does not need a full PRD/PLAN cycle.

## Outcome

Working **JavaScript/TypeScript** code and tests in the open workspace: npm test/build (and project lint/type checks when configured) green, on a valid feature branch, with optional commit handoff. Covers **Node backend** (Express/Fastify; Nest recognized only) **and** existing DOM/`html-css` routes — Node backend is an extension, not a replacement. Does not replace SDD for multi-step or cross-repo features. There is **no** `node-developer` skill.

## Lazy-load (only when needed)

| When | Path (after `scripts/sync-cursor.ps1`) |
|------|----------------------------------------|
| Repo context | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-0-context.md` |
| Before coding | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-0.5-review-guidelines.md` |
| Branching | `{{TOOLKIT_ROOT}}/rules/branch-validation.mdc`, `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-3-branching.md` |
| Pre-commit | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-3.5-precommit-validation.md` |
| Commit / PR | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-4-commits-pr.md`, `{{TOOLKIT_ROOT}}/rules/conventional-commits.mdc` |
| Pre-PR gate | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/step-7-checklist.md` |
| Node backend (Express/Fastify) | `{{TOOLKIT_ROOT}}/skills/_shared/javascript-guidelines/node-backend.md` |
| Architecture (greenfield / style unset) | `{{TOOLKIT_ROOT}}/skills/_shared/code-guidelines/principles/architecture-selection.md` — then **one** approved style only |
| Architecture (ARCH = concentric / clean / hexagonal) | `{{TOOLKIT_ROOT}}/skills/_shared/javascript-guidelines/architecture/concentric.md` (+ optional `principles/architecture/concentric-dependency.md`) |
| Architecture (ARCH = vertical-slice / VSA) | `{{TOOLKIT_ROOT}}/skills/_shared/javascript-guidelines/architecture/vertical-slice.md` (+ optional `principles/architecture/vertical-slice.md`) |
| Architecture (ARCH = event-driven / EDA) | `{{TOOLKIT_ROOT}}/skills/_shared/javascript-guidelines/architecture/event-driven.md` (+ optional `principles/architecture/event-driven.md`) |
| Node security | `{{TOOLKIT_ROOT}}/skills/_shared/javascript-guidelines/node-security.md` |
| Node structure / errors | `{{TOOLKIT_ROOT}}/skills/_shared/javascript-guidelines/node-structure-errors.md` |
| TypeScript strict | `{{TOOLKIT_ROOT}}/skills/_shared/javascript-guidelines/typescript-strict.md` |
| Clean code TS / JS | `{{TOOLKIT_ROOT}}/skills/_shared/javascript-guidelines/clean-code-ts.md`, `{{TOOLKIT_ROOT}}/skills/_shared/javascript-guidelines/clean-code-js.md` |
| Google TS style | `{{TOOLKIT_ROOT}}/skills/_shared/javascript-guidelines/google-ts-style.md` |
| Frontend core (`html-css` / DOM work) | `{{TOOLKIT_ROOT}}/skills/_shared/frontend-guidelines/frontend-practices.md` |
| DOM patterns (`html-css` stack) | `{{TOOLKIT_ROOT}}/skills/_shared/javascript-guidelines/dom-patterns.md` |
| Semantic HTML (`html-css`) | `{{TOOLKIT_ROOT}}/skills/_shared/html-css-guidelines/semantic-html.md` |
| a11y basics (`html-css`) | `{{TOOLKIT_ROOT}}/skills/_shared/html-css-guidelines/accessibility-basics.md` |
| CSS foundations (`html-css`) | `{{TOOLKIT_ROOT}}/skills/_shared/html-css-guidelines/css-foundations.md` |
| Modern CSS (`html-css`) | `{{TOOLKIT_ROOT}}/skills/_shared/html-css-guidelines/modern-css.md` |
| SCSS (`html-css`) | `{{TOOLKIT_ROOT}}/skills/_shared/html-css-guidelines/scss-guidelines.md` |
| Inclusive components (`html-css`) | `{{TOOLKIT_ROOT}}/skills/_shared/html-css-guidelines/inclusive-components.md` |
| HTML/CSS checklist | `{{TOOLKIT_ROOT}}/skills/_shared/html-css-guidelines/checklist.md` |
| Design brief | `docs/DESIGN-BRIEF.md` or `docs/design/DESIGN-BRIEF.md` |
| Subagent-first / SPAWN.md | `{{TOOLKIT_ROOT}}/skills/_shared/developer-common/subagent-first.md`, `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN.md` |
| Caveman Mode (if active) | `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md` - **Full cap** |
| Context pressure | `{{TOOLKIT_ROOT}}/rules/context-management.mdc` |
| Reference index (routing only) | `{{TOOLKIT_ROOT}}/skills/javascript-developer/reference.md` |
| Process step detail (lazy) | `{{TOOLKIT_ROOT}}/skills/javascript-developer/references/<section>.md` |

**Never by default:** do not preload all `references/*.md`. do not preload other stack guideline packs, the full `javascript-guidelines/` tree, all `html-css-guidelines/`, or corporate pipeline docs. Load only the rows needed for the current task. Preserve DOM/`html-css` paths when the task is UI — Node backend docs are additive. **MUST NOT** glob `architecture/**` — load **one** style overlay from ARCH/CONTINUITY (brownfield: discover-first if style omitted). Do not dump full stack guideline packs or memory-bank. Load **one** section per Process step (`SKILL-REFERENCE-RETRIEVAL.md`).

**Progressive load:** `step-0-context.md` first; then `step-0.5-review-guidelines.md` as the index; fan-out to Node vs DOM vs architecture overlay only on trigger. Do not open every `html-css-guidelines/` file for a pure API task (or every Node file for a pure DOM task).

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
| Missing design brief | `/impeccable shape` (new session) |
| Next PLAN step | New chat -> `/sdd-develop - PLAN/... - Step N` |
