# Angular DI, routing, and forms

Dependency injection with `inject()`, route composition, and form patterns. Keep HTTP and business rules in services; components stay thin.

---

## MUST

- Prefer **`inject()`** in field initializers (and functional guards/interceptors) for new code — keeps types inferred and constructors thin.
- Register app-wide services with `providedIn: 'root'` unless a narrower scope already exists for that type.
- Lazy-load feature routes with `loadComponent` / `loadChildren` when the router config already uses code splitting.
- Prefer `routerLink` / `Router` APIs and named routes over `window.location` or raw URL string hacks.
- Use **functional** guards/resolvers/interceptors when the project’s Angular version and codebase already do.
- Prefer **Reactive Forms** (`FormGroup` / `FormControl`) for non-trivial validation; use template-driven only for trivial cases matching repo style.
- Prefer **typed** forms (`FormControl<T>`, `NonNullableFormBuilder`) when `strict` templates/forms are enabled.
- Put validators and async validators on controls; keep submit handlers free of duplicated rule copies.

```typescript
export class OrderEditComponent {
  private readonly orders = inject(OrderService);
  private readonly route = inject(ActivatedRoute);
  private readonly fb = inject(NonNullableFormBuilder);

  readonly form = this.fb.group({
    code: this.fb.control('', { validators: [Validators.required] }),
  });
}
```

```typescript
{
  path: 'orders',
  loadComponent: () => import('./orders/order-list.component').then(m => m.OrderListComponent),
}
```

---

## MUST NOT

- Use field `@Injectable` injection via constructor parameter properties **and** scattered `inject()` inconsistently inside the same new class without reason — pick the style the file/neighbors use (`inject()` preferred for greenfield).
- Provide the same service in both `root` and a component `providers` array unless deliberately creating a new instance tree.
- Eager-load large feature trees when neighboring routes already lazy-load.
- Put HTTP calls or auth token parsing inside route components’ constructors without a service.
- Disable form controls by manipulating the DOM; use Reactive Forms APIs.
- Invent a second forms library (Formly, etc.) when the repo standardizes on Angular forms.

---

## Prefer when matching repo

| Signal | Prefer |
|--------|--------|
| Class-based guards still dominant | Match class guards in touched routes; do not rewrite all guards in a small PR |
| `provideRouter` / `bootstrapApplication` | Functional `ApplicationConfig` providers |
| NgModule `RouterModule.forChild` | Keep module routing until migration |
| Existing `FormBuilder` usage | Continue; adopt `NonNullableFormBuilder` when neighbors do |
| Route `data` / resolvers | Reuse for breadcrumb/title patterns already present |
| HTTP interceptors | Extend existing interceptor chain for auth/errors |

### DI tokens

- Use `InjectionToken` for config and multi-providers when the project already does.
- Prefer `importProvidersFrom` only when wrapping legacy NgModules in a standalone bootstrap.
- Prefer `providedIn: 'root'` over listing the service in `bootstrapApplication` providers unless the token must be overridden per environment.

### Forms checklist (touched screens)

- [ ] Controls created with typed builder when strict forms are on
- [ ] Validators on controls, not duplicated in submit
- [ ] Disabled state via Forms API
- [ ] Error messages bound to control state for a11y (see html-css packs)
- [ ] Submit guarded while pending (`exhaustMap` / disabled flag)

---

## References

- [Angular — Dependency injection](https://angular.dev/guide/di)
- [Angular — Routing overview](https://angular.dev/guide/routing/overview)
- [Angular — Reactive forms](https://angular.dev/guide/forms/reactive-forms)
- [Angular — Lazy loading](https://angular.dev/guide/routing/common-router-tasks#lazy-loading)
