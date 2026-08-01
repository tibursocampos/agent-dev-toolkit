# Angular RxJS lifecycle

Subscription ownership, `takeUntilDestroyed`, async pipe, and Observable hygiene in Angular components and services.

---

## MUST

- Prefer **`async` pipe** or **`toSignal()`** in templates/components so the framework owns teardown.
- When a manual subscription is required in a component, use **`takeUntilDestroyed()`** (from `@angular/core/rxjs-interop`) in the creation injection context (constructor / field initializer), or pass `DestroyRef` explicitly.
- Unsubscribe or complete long-lived streams in services that create them when the owning scope ends (or share via `providedIn` carefully).
- Prefer pure pipe operators (`map`, `filter`, `switchMap`, …) over side effects in `subscribe` next handlers when transformation fits.
- Use **`switchMap`** for “latest in wins” (typeahead, route param → HTTP); **`exhaustMap`** for submit buttons; **`concatMap`** for ordered queues — match intent.
- Handle HTTP errors with `catchError` at the service boundary (or existing error interceptor); surface user-safe messages via the project’s notification pattern.
- Keep cold Observables cold until subscribed; do not start work in constructors without an explicit project pattern for eager load.

```typescript
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';

export class InboxComponent {
  private readonly notifications = inject(NotificationService);

  constructor() {
    this.notifications.messages$
      .pipe(takeUntilDestroyed())
      .subscribe((msg) => this.handle(msg));
  }

  readonly latest = toSignal(this.notifications.messages$, { initialValue: null });
}
```

```html
@if (orders$ | async; as orders) {
  <app-order-list [orders]="orders" />
}
```

---

## MUST NOT

- Leave bare `.subscribe()` in components without teardown.
- Use `subscribe` in the template or in getters that run every change detection cycle.
- Nest subscriptions (`subscribe` inside `subscribe`) — flatten with higher-order mapping operators.
- Call `.unsubscribe()` ad-hoc in random methods when `takeUntilDestroyed` / async pipe already fits.
- Ignore errors (`subscribe({ next })` only) on user-facing loads.
- Use `shareReplay` without a clear multicasting need and buffer policy.

---

## Prefer when matching repo

| Signal | Prefer |
|--------|--------|
| Signals-first UI | `toSignal` at the edge; Observables stay in services |
| Existing `DestroyRef` + `takeUntil` subjects | Match neighbors; prefer `takeUntilDestroyed` for new code |
| Global error interceptor | Let it handle HTTP; avoid duplicate toasts in every call site |
| Polling / websockets | Encapsulate in a service with explicit connect/disconnect |
| Testing marble diagrams | Only when the project already uses `jasmine-marbles` / similar |

### Operator cheatsheet

| Intent | Operator |
|--------|----------|
| Cancel in-flight on new input | `switchMap` |
| Ignore while in-flight | `exhaustMap` |
| Queue in order | `concatMap` |
| Parallel fan-out | `mergeMap` (cap concurrency when needed) |

### Component subscription decision tree

1. Template needs the value → `async` pipe or `toSignal` field.
2. Side effect only (analytics, focus) → `takeUntilDestroyed` subscription or `effect` when Signals-first.
3. Long-lived app bus → service owns the Subject; components consume with (1) or (2).
4. Never subscribe in a getter, pipe pure function, or `@for` track expression.

---

## References

- [Angular — RxJS interop](https://angular.dev/guide/signals/rxjs-interop)
- [takeUntilDestroyed](https://angular.dev/api/core/rxjs-interop/takeUntilDestroyed)
- [RxJS — Higher-order observables](https://rxjs.dev/guide/higher-order-observables)
- [Angular best practices](https://angular.dev/best-practices)
