# 04 — Implement and guidelines

Two implementation paths exist. They are not interchangeable.

| Path | Who writes code | When |
|------|-----------------|------|
| PLAN step | `sdd-develop` child (from [O3](01-orchestrated-delivery.md) or a direct develop session) | A PLAN step exists |
| Small change | `developer` or one `*-developer` | Trivial O1 triage, or work that never entered a feature tree |

O1 may **suggest** `/developer`. It must not call a stack skill to write the feature. O3 must not call `*-developer` for a PLAN step. If Task is missing, O3 hands off to manual `/sdd-develop`, not to `/developer`.

Large scope discovered inside `/developer` hands off to `/sdd-spec` → `sdd-plan` → `sdd-develop`.

## `developer` (router)

Trigger: `/developer`, or coding that does not name a stack.

Order:

1. **UI.** Net-new UI or a visual redesign with no `PRODUCT.md`: recommend `/impeccable init` in a new session. If `docs/DESIGN-BRIEF.md` (or `docs/design/DESIGN-BRIEF.md`) exists, it is the acceptance source; implement with the matching `*-developer` and do not reinterpret the brief. One session is design or implementation, not both.
2. **Stack match.** First hit wins. The router loads that skill and stops. It does not ask permission to switch.

| Signal | Skill |
|--------|--------|
| New Blip plugin, no existing `blip-ds` project | `blip-plugin-developer` |
| `package.json` has `blip-ds` and `iframe-message-proxy` | `react-developer` (also loads `blip-guidelines/`) |
| Blazor markers (`Microsoft.AspNetCore.Components`, `_Imports.razor`, `App.razor`) | `blazor-developer` |
| `electron`, `electron-builder`, or `electron-vite` | `electron-developer` |
| `vue` (and not React or Angular) | `vue-developer` |
| `react-native` or `expo` | `react-native-developer` |
| `react` | `react-developer` |
| `@angular/core` or `angular` | `angular-developer` |
| `package.json` with none of the above | `javascript-developer` |
| `.csproj` / `.sln` without Blazor markers | `dotnet-developer` |
| `pom.xml`, `build.gradle`, `build.gradle.kts`, `settings.gradle` | `java-developer` |
| `.py`, `requirements.txt`, `pyproject.toml` | `python-developer` |

3. **Fallback.** Isolated HTML or shell scripts: stay in `/developer`, micro-plan of two to five tasks, at most two children when subagents are native, offer `/commit`. Do not auto-commit.

Agent-facing copy of the same table: `core/skills/_shared/agents/ROUTING.md`.

## Stack skills

Each one implements **small-to-medium** work in the open workspace. Full multi-step features belong to Classic SDD. Common gates: operator **sim** before writes; one outcome then stop; no guideline dump into child prompts; no auto-commit.

| Skill | Scope | Guideline pack loaded on demand | Hands off when scope grows |
|-------|--------|----------------------------------|----------------------------|
| `dotnet-developer` | .NET backend | `dotnet-guidelines/` (one style: clean architecture, vertical slice, DDD tactical, or event-driven, plus C# patterns) | `/sdd-spec` |
| `java-developer` | JVM, Spring Boot by default | `java-guidelines/` including `architecture/` overlays | `/sdd-spec` |
| `javascript-developer` | Node (Express/Fastify) or DOM. There is no `node-developer` id | `javascript-guidelines/` | `/sdd-spec`; UI brief to impeccable |
| `python-developer` | FastAPI or Flask | `python-guidelines/` plus one shared Layer B style file | `/sdd-spec` |
| `react-developer` | React web. React Native is a different skill | `react-guidelines/`, frontend and HTML/CSS as needed; Blip pack when `blip-ds` is present | `/react-native-developer` for mobile; `/impeccable shape` when the brief is missing |
| `react-native-developer` | React Native / Expo | `react-native-guidelines/` | `/react-developer` for web |
| `angular-developer` | Angular | `angular-guidelines/` plus HTML/CSS | impeccable when the brief is missing |
| `vue-developer` | Vue 3, Composition API, Pinia, Vitest | `vue-guidelines/` | impeccable when the brief is missing |
| `blazor-developer` | WASM, Server, Hybrid | `blazor-guidelines/` one topic at a time; `dotnet-guidelines` patterns; clean architecture only when ARCH is concentric and an API sits behind the UI | `/dotnet-developer` for the API |
| `electron-developer` | Main, preload, renderer, IPC, packaging | `electron-guidelines/` (security/CSP first when IPC changes) plus one renderer pack | impeccable when the brief is missing |
| `blip-plugin-developer` | **New** plugin scaffold, not feature coding | `blip-guidelines/` and the impeccable brief template | Implementation is `/react-developer`. Backend API is `/dotnet-developer` in another repo. Full feature is `/sdd-spec` |

Greenfield or an unset architecture style starts at `architecture-selection.md` instead of guessing a folder layout. Brownfield mirrors the style already in ARCH.

## Guidelines (Layers A, B, C)

Source: `core/skills/_shared/code-guidelines/`. Load one file. Do not preload `languages/**`.

| Layer | Question | File |
|-------|----------|------|
| A | Which style | `principles/architecture-selection.md` |
| B | What the style requires (stack-agnostic) | Exactly one of `architecture/vertical-slice.md`, `concentric-dependency.md`, `ddd-tactical.md` (only after concentric), `event-driven.md` (overlay) |
| C | How this stack does it | The matching `*-guidelines` pack |

Greenfield: propose, set needs-confirm, write final ARCH only after **sim**. The O1 architect runs this gate ([01](01-orchestrated-delivery.md)). Brownfield: mirror. Do not swap style unless the operator asks.

Clean Architecture, onion, and hexagonal are the same concentric rule. Vertical slice is the proposal for CRUD-heavy greenfield, not a silent default. Event-driven does not replace the folder tree. UI-only work uses `frontend-guidelines/frontend-architecture.md` instead of forcing a backend layer tree onto the UI pack.

Packs under `core/skills/_shared/`: `angular-guidelines`, `blazor-guidelines`, `blip-guidelines`, `code-guidelines`, `devops-guidelines`, `dotnet-guidelines`, `electron-guidelines`, `frontend-guidelines`, `html-css-guidelines`, `java-guidelines`, `javascript-guidelines`, `python-guidelines`, `react-guidelines`, `react-native-guidelines`, `vue-guidelines`.

`sdd-develop` loads the same packs one file at a time for the PLAN step. It does not switch into a `*-developer` skill.

## `impeccable`

UI design skill. Trigger: `/impeccable` (menu; does not auto-run), `/impeccable <command>`, or aliases `/impeccable-shape` and `/impeccable-audit`. `teach` is a deprecated alias of `init`.

If `PRODUCT.md` is missing, stop and run `init` before any other command. Register is `brand` (marketing, landing, portfolio) or `product` (app UI). Do not load both unless routing requires it.

Commands that ship in-repo references include `init`, `shape`, `craft`, `critique`, `audit`, `harden`, `polish`, `onboard`. `document` and `extract` are not bundled. `live` and design hooks call `npx impeccable install` and need an explicit **sim**; they write project hook files.

After **sim** on a `shape` or `craft` brief, write `docs/DESIGN-BRIEF.md` from the skill template, set `target_stack`, and **stop**. The next chat implements:

| `target_stack` | Skill |
|----------------|--------|
| `react` | `/react-developer` |
| `react-native` | `/react-native-developer` |
| `angular` | `/angular-developer` |
| `vue` | `/vue-developer` |
| `blazor` | `/blazor-developer` |
| `electron` | `/electron-developer` |
| `html-css` | `/javascript-developer` |
| ambiguous | `/developer` |

Blip section of the brief records design-system components and iframe limits; implementation is still `react-developer` plus `blip-guidelines/`. A large feature that also needs a PRD continues through `sdd-spec`. This repo’s `docs/DESIGN-BRIEF.md` is the toolkit site brief, not a consumer-app brief. Credit: [CREDITS.md](../CREDITS.md).
