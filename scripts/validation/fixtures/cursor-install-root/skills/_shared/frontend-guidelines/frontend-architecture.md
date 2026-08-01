# Frontend architecture (shared hub)

Single **UI structure** hub for React, Vue, Angular, React Native / Expo, and Blazor. Load this file when ARCH / CONTINUITY needs frontend folder layout — **not** a full backend Clean Architecture tree per framework pack.

**Stack:** Cross-UI (presentation / SPA / mobile shell)  
**Layer:** FE structure (pair with selection A when UI-only)  
**Used by:** UI `*-guidelines` packs, architect, brownfield mirror of `app` / `features` / `shared`

> **Selection (WHEN):** `../code-guidelines/principles/architecture-selection.md` (UI-only → this hub)  
> **Backend concentric (WHAT):** `../code-guidelines/principles/architecture/concentric-dependency.md` — only when the **API** side is concentric; do not paste that essay into UI packs.

---

## Core idea

Frontends organize by **feature / product surface**, not by global Domain / Application / Infrastructure projects.

```
app/                 # shell: routing, providers, layouts (thin)
features/<name>/     # vertical UI capability (pages, hooks, local UI state)
shared/              # cross-feature presentational UI, utils, design primitives
```

Names may be `src/features`, `modules`, `pages` + `components` — **mirror the repo**. The rule is feature cohesion + thin shell, not a mandatory three-folder rename.

---

## MUST

- Discover existing UI layout first (brownfield); extend the nearest feature folder the same way neighbors do.
- Keep the **app shell thin**: routing, providers, auth gates, layout chrome — no business rules dumped into root layouts.
- Colocate UI that changes together under `features/<name>/` (screens/pages, feature hooks/composables/services, local types).
- Put reusable presentational pieces and pure helpers in `shared/` (or the repo’s `shared` / `ui` / `components` equivalent) — not a dumping ground for unfinished features.
- When ARCH / CONTINUITY asks for FE structure, **load this hub** from the active UI pack; do not invent a second architecture essay inside React/Vue/Angular/RN/Blazor files.
- Map framework terms to the same idea: React routes/pages, Vue/Nuxt pages + composables, Angular feature folders, Expo Router `app/` routes, Blazor `Pages` / feature components.
- Keep identifiers, comments, and logs in **English**.

| Concern | Lives in |
|---------|----------|
| Route / screen entry | `app/` or feature `pages` / `screens` registered by shell |
| Feature UI + local rules | `features/<name>/` |
| Dumb shared UI | `shared/` (or repo equivalent) |
| Server / API contracts | Client API module at the edge — not duplicated domain projects per widget |

---

## MUST NOT

- Duplicate **full** Clean Architecture / Onion / Hexagonal project trees inside React, Vue, or Angular packs (no per-framework `Domain` / `Application` / `Infrastructure` CA essays).
- Force global backend concentric folders onto a SPA or mobile client when the repo is feature-first.
- Copy this hub’s body into every UI checklist — **pointer + load path only** in packs.
- Invent a parallel tree (`containers/` vs `features/`, second `shared-ui/`) beside an established layout without an explicit migration ask.
- Put cross-cutting API clients, auth, and design tokens only inside one random feature so other features import sideways forever — promote true shared pieces deliberately.
- Treat Feature-Sliced Design (FSD) layers as mandatory when the repo never adopted FSD.
- Glob-load every UI guideline file “for architecture”; load **this** hub + the framework files needed for the task.

---

## Prefer when matching repo

### Feature-first (`app` / `features` / `shared`)

- Prefer feature folders when the tree already groups by domain or product surface.
- Prefer thin route files that import feature entry components — keep data hooks and UI state next to the feature.
- Prefer one shared design/primitives package (or `shared/ui`) already in the monorepo rather than a new component library.

### Optional CA-in-feature hybrid

- Prefer **local** rings inside a feature only when the feature already separates UI / application hooks / data adapters **within that folder** (e.g. `features/orders/{ui,model,api}`).
- Prefer this hybrid for complex features — **not** a solution-wide backend CA layout forced onto every component.
- Prefer keeping “domain-like” types as feature-local models or shared API DTOs; do not create a global `Domain` project for the SPA alone.

### Feature-Sliced Design (FSD)

- Prefer FSD (`app` / `processes` / `pages` / `widgets` / `features` / `entities` / `shared`) **only when** the repo already uses FSD (public API per slice, layer import rules).
- Prefer respecting FSD public APIs (`index` barrels) when present — do not deep-import across slices against the project’s lint rules.
- Prefer **not** introducing FSD mid-feature into a classic `features/` + `shared/` tree without operator approval.

### React Native / Expo

- Prefer **Expo Router** as a **thin shell**: file routes and layouts under `app/` import screens/hooks from `features/` (or existing colocated modules) — navigation chrome stays thin.
- Prefer one navigator family (Expo Router **or** React Navigation) as already adopted; see `react-native-guidelines/structure-and-navigation.md` for HOW.
- Prefer shared RN UI in the repo’s shared package; do not fork web DOM patterns into native screens.

### Blazor + .NET API

- Prefer Blazor feature/page folders for UI; when the **same solution** hosts concentric API projects, load `dotnet-guidelines/clean-architecture.md` for API rings and **this hub** for UI structure.
- Prefer Blazor components as presentation/adapters — business rules stay in Application/Domain on the API side when that layout exists.

---

## UI pack load rule

| Pack | When to load this hub |
|------|------------------------|
| `react-guidelines/` | ARCH / CONTINUITY needs React web folder layout |
| `vue-guidelines/` | Same for Vue / Nuxt |
| `angular-guidelines/` | Same for Angular feature/core/shared |
| `react-native-guidelines/` | Same for Expo / RN shell + features |
| `blazor-guidelines/` | Same for Blazor pages/features (+ dotnet CA when API+UI) |

Framework packs keep stack HOW (hooks, Signals, SFCs, bUnit). **Structure policy lives here once.**

---

## Review checklist

- [ ] Shell (`app` / layouts / router) stays thin
- [ ] New UI landed in an existing feature folder (or justified new feature)
- [ ] No new global CA tree for the SPA/mobile client alone
- [ ] FSD used only if repo already FSD
- [ ] RN: Expo Router (or RN Navigation) remains a thin overlay over features
- [ ] Blazor+API: UI hub + dotnet concentric HOW each for their side

---

## Related guidelines

- Practices / testing hubs: `frontend-practices.md`, `frontend-testing.md`
- Selection A: `../code-guidelines/principles/architecture-selection.md`
- Backend concentric B (API only): `../code-guidelines/principles/architecture/concentric-dependency.md`
- RN navigation HOW: `../react-native-guidelines/structure-and-navigation.md`
- Dotnet CA HOW (API): `../dotnet-guidelines/clean-architecture.md`

---

## References

- [Feature-Sliced Design](https://feature-sliced.design/)
- [Expo Router — Introduction](https://docs.expo.dev/router/introduction/)
- [Angular — Style guide (feature structure)](https://angular.dev/style-guide)
- [Next.js — Project structure / App Router](https://nextjs.org/docs/app/getting-started/project-structure)
