# 04 — Implement and guidelines

Two implementation paths exist. They are not interchangeable.

| Path | Who writes code | When |
|------|-----------------|------|
| PLAN step | `adt-sdd-develop` child (from [O3](01-orchestrated-delivery.md) or a direct develop session) | A PLAN step exists |
| Small change | `adt-developer` or one `adt-*-developer` | Trivial O1 triage, or work that never entered a feature tree |

O1 may **suggest** `/adt-developer`. It must not call a stack skill to write the feature. O3 must not call `adt-*-developer` for a PLAN step. If Task is missing, O3 hands off to manual `/adt-sdd-develop`, not to `/adt-developer`.

Large scope discovered inside `/adt-developer` hands off to `/adt-sdd-spec` → `adt-sdd-plan` → `adt-sdd-develop`.

## `adt-developer` (router)

Trigger: `/adt-developer`, or coding that does not name a stack.

Order:

1. **UI.** For net-new UI or a substantial visual redesign, clarify the product context and record visual decisions in `docs/DESIGN-BRIEF.md`. If `docs/DESIGN-BRIEF.md` (or `docs/design/DESIGN-BRIEF.md`) exists, it is the acceptance source; implement with the matching `adt-*-developer` and do not reinterpret the brief. Keep substantial design discovery and implementation in separate sessions.
2. **Stack match.** First hit wins. The router loads that skill and stops. It does not ask permission to switch.

| Signal | Skill |
|--------|--------|
| New Blip plugin, no existing `blip-ds` project | `adt-blip-plugin-developer` |
| `package.json` has `blip-ds` and `iframe-message-proxy` | `adt-react-developer` (also loads `blip-guidelines/`) |
| Blazor markers (`Microsoft.AspNetCore.Components`, `_Imports.razor`, `App.razor`) | `adt-blazor-developer` |
| `electron`, `electron-builder`, or `electron-vite` | `adt-electron-developer` |
| `vue` (and not React or Angular) | `adt-vue-developer` |
| `react-native` or `expo` | `adt-react-native-developer` |
| `react` | `adt-react-developer` |
| `@angular/core` or `angular` | `adt-angular-developer` |
| `package.json` with none of the above | `adt-javascript-developer` |
| `.csproj` / `.sln` without Blazor markers | `adt-dotnet-developer` |
| `pom.xml`, `build.gradle`, `build.gradle.kts`, `settings.gradle` | `adt-java-developer` |
| `.py`, `requirements.txt`, `pyproject.toml` | `adt-python-developer` |

3. **Fallback.** Isolated HTML or shell scripts: stay in `/adt-developer`, micro-plan of two to five tasks, at most two children when subagents are native, offer `/adt-commit`. Do not auto-commit.

Agent-facing copy of the same table: `core/skills/_shared/agents/ROUTING.md`.

## Stack skills

Each one implements **small-to-medium** work in the open workspace. Full multi-step features belong to Classic SDD. Common gates: operator `confirm` answer before writes; one outcome then stop; no guideline dump into child prompts; no auto-commit.

| Skill | Scope | Guideline pack loaded on demand | Hands off when scope grows |
|-------|--------|----------------------------------|----------------------------|
| `adt-dotnet-developer` | .NET backend | `dotnet-guidelines/` (one style: clean architecture, vertical slice, DDD tactical, or event-driven, plus C# patterns) | `/adt-sdd-spec` |
| `adt-java-developer` | JVM, Spring Boot by default | `java-guidelines/` including `architecture/` overlays | `/adt-sdd-spec` |
| `adt-javascript-developer` | Node (Express/Fastify) or DOM. There is no `node-developer` id | `javascript-guidelines/` | `/adt-sdd-spec`; create a UI brief when substantial visual decisions are needed |
| `adt-python-developer` | FastAPI or Flask | `python-guidelines/` plus one shared Layer B style file | `/adt-sdd-spec` |
| `adt-react-developer` | React web. React Native is a different skill | `react-guidelines/`, frontend and HTML/CSS as needed; Blip pack when `blip-ds` is present | `/adt-react-native-developer` for mobile; create a brief when substantial visual decisions are needed |
| `adt-react-native-developer` | React Native / Expo | `react-native-guidelines/` | `/adt-react-developer` for web |
| `adt-angular-developer` | Angular | `angular-guidelines/` plus HTML/CSS | create a brief when substantial visual decisions are needed |
| `adt-vue-developer` | Vue 3, Composition API, Pinia, Vitest | `vue-guidelines/` | create a brief when substantial visual decisions are needed |
| `adt-blazor-developer` | WASM, Server, Hybrid | `blazor-guidelines/` one topic at a time; `dotnet-guidelines` patterns; clean architecture only when ARCH is concentric and an API sits behind the UI | `/adt-dotnet-developer` for the API |
| `adt-electron-developer` | Main, preload, renderer, IPC, packaging | `electron-guidelines/` (security/CSP first when IPC changes) plus one renderer pack | create a brief when substantial visual decisions are needed |
| `adt-blip-plugin-developer` | **New** plugin scaffold, not feature coding | `blip-guidelines/` | Implementation is `/adt-react-developer`. Backend API is `/adt-dotnet-developer` in another repo. Full feature is `/adt-sdd-spec` |

When a concrete architecture choice affects behavior or implementation, consult `architecture-selection.md` and resolve the material decision. Greenfield, unset style, or brownfield classification alone does not require an architecture mirror or confirmation gate.

## Guidelines (Layers A, B, C)

Source: `core/skills/_shared/code-guidelines/`. Load one file. Do not preload `languages/**`.

| Layer | Question | File |
|-------|----------|------|
| A | Which style | `principles/architecture-selection.md` |
| B | What the style requires (stack-agnostic) | Exactly one of `architecture/vertical-slice.md`, `concentric-dependency.md`, `ddd-tactical.md` (only after concentric), `event-driven.md` (overlay) |
| C | How this stack does it | The matching `*-guidelines` pack |

Greenfield: propose, set needs-confirm, write final ARCH only after a `confirm` answer. The O1 architect runs this gate ([01](01-orchestrated-delivery.md)). Brownfield: mirror. Do not swap style unless the operator asks.

Clean Architecture, onion, and hexagonal are the same concentric rule. Vertical slice is the proposal for CRUD-heavy greenfield, not a silent default. Event-driven does not replace the folder tree. UI-only work uses `frontend-guidelines/frontend-architecture.md` instead of forcing a backend layer tree onto the UI pack.

Packs under `core/skills/_shared/`: `angular-guidelines`, `blazor-guidelines`, `blip-guidelines`, `code-guidelines`, `devops-guidelines`, `dotnet-guidelines`, `electron-guidelines`, `frontend-guidelines`, `html-css-guidelines`, `java-guidelines`, `javascript-guidelines`, `python-guidelines`, `react-guidelines`, `react-native-guidelines`, `vue-guidelines`.

`adt-sdd-develop` loads the same packs one file at a time for the PLAN step. It does not switch into a `adt-*-developer` skill.
