# Angular standalone and templates

Standalone APIs and modern control flow for Angular 17+. Absorbs prior stub guidance from `angular-skills` / `best-practices`. For Signals see `signals-and-state.md`.

---

## MUST

- Declare new `Component`, `Directive`, and `Pipe` instances as **standalone** (`standalone: true` or the CLI default that emits standalone).
- List every directive, pipe, and child component used in the template in `@Component.imports` (or the equivalent `imports` on directive/pipe metadata).
- Use built-in control flow **`@if` / `@for` / `@switch` / `@defer`** in new templates — not new `*ngIf` / `*ngFor` / `*ngSwitch`.
- Always provide a **`track`** expression on `@for` (stable entity id; never omit).
- Prefer `@empty` blocks for empty lists instead of a separate sibling `*ngIf`.
- Keep templates declarative: move non-trivial expressions into `computed()` / methods / pipes already used by the project.
- Use semantic host elements and accessible labels; defer shared a11y essays to `frontend-guidelines/` and `html-css-guidelines/`.

```typescript
@Component({
  selector: 'app-order-list',
  standalone: true,
  imports: [CurrencyPipe, OrderRowComponent],
  templateUrl: './order-list.component.html',
})
export class OrderListComponent {
  readonly orders = input.required<Order[]>();
}
```

```html
@for (order of orders(); track order.id) {
  <app-order-row [order]="order" />
} @empty {
  <p>No orders</p>
}

@if (selected(); as order) {
  <app-order-detail [order]="order" />
}
```

---

## MUST NOT

- Add new NgModules solely to declare components when the app is standalone-first.
- Introduce new `*ngIf` / `*ngFor` / `ng-template` structural directives for greenfield templates on Angular 17+.
- Ship templates that reference undeclared imports (broken standalone boundary).
- Use `@for` without `track`.
- Put business orchestration or HTTP calls in the template.
- Wrap every leaf in unnecessary `NgIf`/`@if` when CSS/`@empty` already handles the empty state.

---

## Prefer when matching repo

| Signal | Prefer |
|--------|--------|
| Angular 16 or older, or heavy `*ngIf` codebase | Match legacy structural directives in touched files; do not mass-migrate in a small PR |
| NgModule feature still owning declarations | Extend that module until a dedicated migration task exists |
| Shared UI library | Import the library’s standalone exports or NgModule the project already uses |
| `@defer` already in routes/views | Use for below-the-fold / heavy widgets with matching triggers |
| OnPush presentational components | Keep OnPush; avoid impure pipes that defeat it |
| i18n (`$localize` / ICU) | Follow existing extraction; do not invent a second i18n stack |

### Import hygiene

- Prefer concrete standalone imports over barrel re-exports that pull half the app.
- Re-export shared UI only when the feature already uses a local barrel.
- Import `NgOptimizedImage` (or the project image directive) only when images need it — do not blanket-import `CommonModule` if the CLI/neighbors import pipes/directives à la carte.

### Control-flow migration note

When touching a legacy template, prefer converting the **local** `*ngIf`/`*ngFor` you edit to `@if`/`@for` if the app is on Angular 17+ and neighboring templates already migrated. Do not convert an entire feature tree in a one-line bugfix.

---

## References

- [Angular — Standalone](https://angular.dev/guide/components/importing)
- [Angular — Control flow](https://angular.dev/guide/templates/control-flow)
- [Angular — Deferred loading](https://angular.dev/guide/templates/defer)
- [Angular best practices](https://angular.dev/best-practices)
