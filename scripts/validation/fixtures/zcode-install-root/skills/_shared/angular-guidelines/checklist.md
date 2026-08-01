# Angular delivery checklist

Use before opening a pull request. Prefer modern standalone + Signals + control flow on greenfield; otherwise match the project’s Angular generation.

When ARCH or CONTINUITY needs frontend folder layout, load `../frontend-guidelines/frontend-architecture.md` (shared hub: feature-first `app` / `features` / `shared`) — do not invent a full Clean Architecture tree inside this Angular pack.

---

## Preparation

- [ ] `AGENTS.md` / README and relevant skills reviewed
- [ ] PLAN step (if applicable) understood
- [ ] Acceptance criteria clear
- [ ] Angular version / standalone vs NgModule approach confirmed from the repo

---

## Branching

- [ ] Working branch: `feature/<slug>` or `feat/<id>-<slug>`
- [ ] Based on the correct default branch (`main` / `develop` / team default)

---

## Implementation

- [ ] Standalone default for new components/directives/pipes (unless legacy module owns them)
- [ ] Templates use `@if` / `@for` with `track` (no new `*ngIf` / `*ngFor` on modern apps)
- [ ] State via Signals + `input()` / `output()` / `inject()` where greenfield
- [ ] Subscriptions use `takeUntilDestroyed` or async pipe / `toSignal`
- [ ] HTTP and business rules in services; components thin
- [ ] Routes lazy-load when neighboring features already do
- [ ] Forms: Reactive + typed when the project is strict
- [ ] a11y basics (labels, keyboard) for touched UI — see hub frontend / html-css packs
- [ ] Identifiers and comments in **English**
- [ ] Changes follow `angular-guidelines` (load files needed for the task)

---

## Style and structure

- [ ] Kebab-case `*.component.ts` naming; one public type per file
- [ ] Feature / core / shared layout matched
- [ ] No reliance on retired johnpapa classic as primary style source — use angular.dev

---

## Tests (new or changed behavior)

- [ ] Arrange / Act / Assert
- [ ] Behavior assertions (DOM / outputs / HTTP mocks)
- [ ] Http testing module / provider used for HTTP
- [ ] No flaky async left hanging
- [ ] Names match repo style

---

## Build

```bash
ng test
ng build
```

(or project-equivalent scripts)

- [ ] Targeted tests green for changed code
- [ ] Production build succeeds when required by the task

---

## Prefer when matching repo

| Signal | Action |
|--------|--------|
| ARCH / CONTINUITY needs FE structure | Prefer load `../frontend-guidelines/frontend-architecture.md` |

---

## Before PR

- [ ] Diff limited to stated acceptance (YAGNI)
- [ ] No new NgModules or state libraries without need
- [ ] Conventional commit message ready (via `/commit` when requested)
- [ ] Guideline paths touched: `style-and-structure`, `standalone-and-templates`, `signals-and-state`, `di-routing-forms`, `rxjs-lifecycle`, `testing` as applicable

---

## References

- [Angular style guide](https://angular.dev/style-guide)
- [Angular best practices](https://angular.dev/best-practices)
- [Angular — Testing](https://angular.dev/guide/testing)
- [Angular — Signals](https://angular.dev/guide/signals)
