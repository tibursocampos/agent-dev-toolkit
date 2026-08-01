---
name: impeccable
description: Design, shape, critique, audit, and polish frontend UI; writes docs/DESIGN-BRIEF.md for stack handoff. Use for UI/UX design work or when invoking /impeccable.
---


## STOP - Read before ANY tool call

1. Read `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/grok/.grok/rules/guardrails.md`
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

## Trigger

Use when user asks for `/impeccable`, `/impeccable`, or any Impeccable command (`shape`, `audit`, `polish`, `craft`, etc.).

**Invocation forms:**

| User says | Behavior |
|-----------|----------|
| `/impeccable` | Context-aware menu; no auto-run |
| `/impeccable <command> [target]` | Load `reference/<command>.md` and execute |
| `/impeccable-shape` | Alias: `shape` command |
| `/impeccable-audit` | Alias: `audit` command |

## Outcome

Production-grade UI design artifacts and/or code per upstream Impeccable command flow. `shape`/`craft` shape phase writes `docs/DESIGN-BRIEF.md` after user confirmation.

## Lazy-load (mandatory per command)

| When | Path (after `sync-cursor.ps1`) |
|------|--------------------------------|
| Any sub-command | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/grok/skills/impeccable/reference/<command>.md` - **required before acting** |
| Register | `reference/brand.md` or `reference/product.md` per routing rules below |
| DESIGN-BRIEF contract | `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/grok/skills/impeccable/reference/DESIGN-BRIEF-TEMPLATE.md` |
| Hooks / live install | `reference/hooks.md` + `docs/impeccable-integration.md` |
| Integration docs | `docs/impeccable-integration.md` in toolkit repo |

Do **not** preload all 28 references. Load only the command reference + register for the current task.

## Setup (every session, before commands)

1. **Project context:** Read `PRODUCT.md` from workspace root (or monorepo target path). If missing -> **STOP** and run `init` flow (`reference/init.md`) before any other command.
2. If `DESIGN.md` exists, read it. If the user named a target path in a monorepo, scope context to that path.
3. **Sub-command:** If the user invoked a command (`craft`, `shape`, `audit`, …), read `reference/<command>.md` next. Non-optional.
4. **Code familiarity:** Read at least one project UI file (CSS/tokens/theme/representative component).
5. **Register (non-optional):** Marketing/landing/portfolio -> `reference/brand.md`. App UI/dashboard/tool -> `reference/product.md`. Use task cue, then surface in focus, then `register` in PRODUCT.md.
6. **New project palette:** If no committed brand colors in tokens, compose OKLCH palette per register refs. Skip if existing tokens define brand colors.

## Design guidance (summary - full rules in references)

Produce production-grade code and design choices. Match-and-refuse absolute bans:

- Side-stripe borders, gradient text, glassmorphism as default
- Hero-metric template, identical card grids, eyebrow on every section
- Numbered section markers (01/02/03) as default scaffolding
- Text overflow at breakpoints; cream/sand/beige body backgrounds (OKLCH warm-neutral band)
- Overused fonts (Inter as default); bounce/elastic easing; `transition-all` reflex
- Cards as lazy default; nested cards always wrong
- Image hover transforms (Tailwind group-hover on images)

**Typography:** body ≤65-75ch; display clamp max ≤6rem; letter-spacing floor ≥-0.04em on display headings.

**Motion:** ease-out-quart/quint/expo; `@media (prefers-reduced-motion: reduce)` on every animation.

**Color:** OKLCH; verify contrast (4.5:1 body, 3:1 large); pick color strategy (Restrained / Committed / Full palette / Drenched) before picking colors.

**Slop test:** If someone could say "AI made that" without doubt, it failed. Run first-order and second-order category-reflex checks (see register refs).

## Commands

| Command | Category | Reference |
|---------|----------|-----------|
| `init` | Build | `reference/init.md` |
| `shape [feature]` | Build | `reference/shape.md` |
| `craft [feature]` | Build | `reference/craft.md` |
| `document` | Build | `reference/document.md` (not bundled - suggest `npx impeccable` or sync refs) |
| `extract [target]` | Build | not bundled initially |
| `critique [target]` | Evaluate | `reference/critique.md` |
| `audit [target]` | Evaluate | `reference/audit.md` |
| `polish [target]` | Refine | `reference/polish.md` |
| `harden [target]` | Refine | `reference/harden.md` |
| `onboard [target]` | Refine | `reference/onboard.md` |
| `animate`, `colorize`, `typeset`, `layout`, `bolder`, `quieter`, `distill`, `delight`, `overdrive`, `clarify`, `adapt`, `optimize` | Various | sync additional refs via `sync-impeccable-refs.ps1` |
| `live` | Iterate | requires per-project install (see below) |
| `hooks` | Manage | `reference/hooks.md` - requires per-project install |

`teach` is deprecated alias for `init`.

## Routing rules

1. **No command argument:** Context-aware menu. If `PRODUCT.md` missing, you are in `init`. Otherwise recommend 2-3 commands with one-line reasons, then full menu. Never auto-run.
2. **First word matches a command:** Load its reference and follow it. Remainder is the target.
3. **Intent maps clearly to one command** (e.g. "fix spacing" -> `layout`): load that reference. Ask once if ambiguous.
4. **No clear match:** Apply setup, general rules, and register reference.

## Detector bridge (`audit`, optional pre-`polish`)

When `reference/audit.md` calls for detector output, run:

```bash
npx impeccable detect --json <paths>
```

- No project install required; `npx` fetches the npm package transiently.
- Requires Node/npm and `write_confirmed` / shell gate approval.
- Fold JSON hits into the audit report per `audit.md` scoring (5 dimensions, P0-P3).

If `npx` fails, continue with manual audit per reference; note detector was skipped.

## Per-project install (live, design hook) - never automatic

`npx impeccable install` writes `.cursor/hooks.json`, `.impeccable/`, and local skill copy. **Violates toolkit guardrails if run without explicit user consent.**

When user requests `live` or design hook:

1. **STOP** - ask user **(pt-BR):** *"Isso exige `npx impeccable install` neste projeto (grava `.cursor/hooks.json` e `.impeccable/`). Posso rodar? (sim / não)"*
2. Only after **sim** -> Shell with install.
3. Document hook coexistence: merge with toolkit hooks per `docs/HOOKS.md` and `docs/impeccable-integration.md`.

## DESIGN-BRIEF handoff (shape / craft)

After user **confirms** the design brief:

1. Write `docs/DESIGN-BRIEF.md` using `reference/DESIGN-BRIEF-TEMPLATE.md` (stack-neutral sections 1-10).
2. Set `target_stack` from workspace detection or user input.
3. For **Blip plugins** (`blip-ds` in `package.json`): document BDS components, iframe constraints, and Lite vs Full profile notes in brief **section 9**; implementation uses `react-developer` + `blip-guidelines/`.
4. **STOP session** - one session = design OR implementation, not both.
5. Ask user **(pt-BR):** *"Brief salvo. Inicie nova conversa com `/<stack>-developer` para implementar."*

| `target_stack` | Next skill |
|----------------|------------|
| `react` | `/react-developer` |
| `react-native` | `/react-native-developer` |
| `angular` | `/angular-developer` |
| `vue` | `/vue-developer` |
| `blazor` | `/blazor-developer` |
| `electron` | `/electron-developer` |
| `html-css` / vanilla | `/javascript-developer` |
| ambiguous | `/developer` (router) |

SDD composability: `shape` may also feed PRD sections when user is in SDD flow; prefer `DESIGN-BRIEF.md` for frontend handoff.

## SDD session rule

One invocation = one Impeccable command outcome. After `shape` brief is saved, or after `polish`/`audit` report, **STOP**. Do not continue to `react-developer` in the same session.

#--------|------|
| Brief confirmed | New session -> `react-developer` / `angular-developer` / `developer` |
| Large feature + PRD | `sdd-spec` -> `sdd-plan` -> `sdd-develop` |
| Commit design artifacts | `/commit` (user request only) |
| More Impeccable commands | New session -> `/impeccable <command>` |
