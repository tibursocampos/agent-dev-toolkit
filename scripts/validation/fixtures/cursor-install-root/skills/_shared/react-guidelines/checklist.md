# React delivery checklist

Use before opening a pull request for React **web** work. Prefer Jest/Vitest + RTL on greenfield; otherwise match the project’s test stack. For mobile, use `react-native-guidelines/checklist.md`.

When ARCH or CONTINUITY needs frontend folder layout, load `../frontend-guidelines/frontend-architecture.md` (shared hub: feature-first `app` / `features` / `shared`) — do not invent a full Clean Architecture tree inside this React pack.

---

## Preparation

- [ ] `AGENTS.md` / README and relevant skills reviewed
- [ ] PLAN step (if applicable) understood; acceptance criteria clear
- [ ] React web confirmed (not RN-only); Blip/`blip-ds` detected if relevant
- [ ] Loaded only needed files from this pack + `frontend-guidelines/`
- [ ] DESIGN-BRIEF consulted when present (do not reinterpret visuals)

---

## Branching

- [ ] Working branch: `feature/<slug>` or `feat/<id>-<slug>`
- [ ] Based on the correct default branch (`main` / `develop` / team default)

---

## Components and state

- [ ] Presentation stays thin; logic in hooks/services per `components-and-state.md`
- [ ] UI state local; server/async state via project data layer (`data-fetching.md`)
- [ ] Derived values in render — no Effect state→state for simple sync (`hooks-and-effects.md`)
- [ ] Stable list keys (IDs); no index keys on mutable lists
- [ ] Feature-folder layout matched when the repo uses it
- [ ] No second global store introduced beside the project standard

---

## Hooks and App Router

- [ ] Rules of Hooks respected (no conditional/loop calls)
- [ ] Effects only for external sync; cleanup present
- [ ] `'use client'` only where interactivity/Hooks require it (App Router)
- [ ] Memo/`useCallback` only with Profiler evidence (`performance.md`)
- [ ] No casual `exhaustive-deps` disable without documented reason

---

## Accessibility and tests

- [ ] Labels/roles/keyboard for changed controls (`accessibility.md`)
- [ ] Focus management for new dialogs/drawers
- [ ] RTL: `getByRole` + `userEvent` for changed behavior (`testing.md`)
- [ ] Shared fixtures under test-utils — no duplicated arrange blocks
- [ ] Names: `should_<result>_when_<condition>` (or repo equivalent)
- [ ] Loading/error/empty UI covered when the change touches those states

---

## Validate

```bash
npm test
npm run build
```

(or project-equivalent scripts)

- [ ] Failures in scope fixed before handoff
- [ ] No secrets in client env or source
- [ ] Identifiers/comments in **English**
- [ ] `/commit` offered — do not auto-commit

---

## Prefer when matching repo

| Signal | Action |
|--------|--------|
| ARCH / CONTINUITY needs FE structure | Prefer load `../frontend-guidelines/frontend-architecture.md` |
| DESIGN-BRIEF present | Treat as acceptance; do not reinterpret visuals |
| Cypress for BDS | Prefer Blip testing guidance over forcing Jest DOM |
| Monorepo packages | Run the package’s test/build scripts, not only root guess |
| React Compiler on | Skip reflexive memo; still measure hot paths |

### Pack map (load only what you need)

| Concern | File |
|---------|------|
| Structure / state | `components-and-state.md` |
| Hooks / Effects | `hooks-and-effects.md` |
| Fetch / cache | `data-fetching.md` |
| Perf / `'use client'` | `performance.md` |
| a11y | `accessibility.md` |
| RTL | `testing.md` |

---

## References

- Pack files in this folder
- [React docs](https://react.dev/)
- Hub: `frontend-guidelines/frontend-practices.md`, `frontend-testing.md`
- Next.js App Router rendering docs (when applicable)
