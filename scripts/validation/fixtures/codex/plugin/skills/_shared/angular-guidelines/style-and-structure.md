# Angular style and structure

Naming, file layout, and feature organization for Angular apps. Canonical source is **angular.dev** style guide / best practices — not the classic johnpapa guide (retired as primary). Cross-cutting a11y/tests live in `frontend-guidelines/` — do not duplicate those paragraphs here.

---

## MUST

- Name files with kebab-case and a type suffix: `[name].[type].ts` (e.g. `order-list.component.ts`, `order.service.ts`, `auth.guard.ts`).
- Co-locate unit specs as `*.spec.ts` next to the source file.
- Define **one** top-level component, directive, pipe, or service per file (rule of one).
- Use a consistent custom element prefix on component selectors (kebab-case); attribute selectors stay camelCase with the same prefix.
- Split template and styles into `.component.html` / `.component.css` (or `.scss`) when either exceeds ~3 lines or the project already externalizes them.
- Group by **feature / domain folder** when the repo already does; place singletons (interceptors, app-wide guards) under the project’s `core/` (or equivalent); shared presentational pieces under `shared/`.
- Keep identifiers, comments, and source English; user-facing copy follows repo i18n.
- Prefer feature-scoped folders over dumping everything by technical role when both patterns exist in the tree.

```
src/app/
  core/                 # singleton services, interceptors, guards
  shared/               # dumb UI, pipes, directives
  features/orders/
    order-list.component.ts
    order-list.component.html
    order.service.ts
    order-list.component.spec.ts
```

---

## MUST NOT

- Treat johnpapa `angular-styleguide` (AngularJS / early Angular) as the normative source for new code.
- Put multiple public components or services in one file “for convenience.”
- Invent a second folder scheme (`modules/`, `pages/`, `containers/`) when the repo already standardizes on features/core/shared.
- Use generic selectors without a project prefix (`selector: 'button'`, `selector: 'card'`).
- Inline huge templates/styles in `@Component` when the project standard is external files.
- Duplicate hub `frontend-guidelines/` essays into Angular files; load the hub instead.

---

## Prefer when matching repo

| Signal | Prefer |
|--------|--------|
| Nx / workspace libs | Follow lib boundaries and `project.json` tags already in use |
| Path aliases (`@app/...`) | Import via existing aliases; do not add a parallel alias set |
| SCSS vs CSS | Match `style` / `inlineStyleLanguage` in `angular.json` |
| Standalone-first apps | No new NgModules for features (see `standalone-and-templates.md`) |
| Legacy NgModule apps | Extend existing modules; migrate only when asked |
| Strict templates / typed forms | Keep `strictTemplates` and typed forms consistent with `tsconfig` |

### SOLID habits (Angular-shaped)

| Principle | Habit |
|-----------|--------|
| SRP | One UI or service responsibility per file |
| DIP | Components depend on injectable services/tokens, not concrete HTTP clients inlined in the class |
| ISP | Prefer focused inputs/`input()` over mega config objects |

### Naming quick reference

| Artifact | Pattern |
|----------|---------|
| Component class | `OrderListComponent` |
| Component file | `order-list.component.ts` |
| Service | `OrderService` / `order.service.ts` |
| Guard | `authGuard` or `AuthGuard` matching neighbors |
| Pipe | `currencyFormat` / `currency-format.pipe.ts` |
| Spec | same basename + `.spec.ts` |

Keep the custom selector prefix stable across the app (`app-`, `ag-`, design-system prefix). Document the prefix only if the repo lacks one — otherwise copy neighbors.

---

## References

- [Angular style guide](https://angular.dev/style-guide)
- [Angular best practices](https://angular.dev/best-practices)
- [Angular — Project structure](https://angular.dev/reference/configs/file-structure)
- [Angular — Building dynamic forms (structure cues)](https://angular.dev/guide/forms)
