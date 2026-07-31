# Angular Signals and state

Local and shared reactivity with Signals, signal inputs/outputs, and RxJS bridges. Absorbs prior `angular-skills` signal sections. For subscription cleanup see `rxjs-lifecycle.md`.

---

## MUST

- Prefer **`signal()` / `computed()` / `effect()`** (when needed) for local component and service UI state on modern Angular.
- Use **`input()` / `input.required()`** and **`output()`** for new component APIs — not `@Input()` / `@Output() EventEmitter` in greenfield.
- Use signal queries (`viewChild`, `viewChildren`, `contentChild`, …) instead of classic decorator queries for new code.
- Derive values with `computed()`; do not mirror one signal into another via manual assignment in event handlers when derivation fits.
- Expose service state to consumers as **read-only** (`asReadonly()` / readonly signals) when mutation must stay inside the service.
- Bridge HTTP/Observables with **`toSignal()`** (or `async` pipe) rather than manual subscribe + push into a field, when the template only needs the latest value.
- Keep **UI state** (panels, selection) separate from **server/async state** (entities from APIs); do not duplicate query results into writable signals “for convenience.”
- Use `effect()` sparingly — for synchronization with imperative APIs, not as a substitute for `computed()`.

```typescript
readonly userId = input.required<string>();
readonly theme = input<'light' | 'dark'>('light');
readonly saved = output<string>();

private readonly store = inject(OrderStore);
readonly orders = this.store.orders.asReadonly();
readonly count = computed(() => this.orders().length);

private readonly routeOrders = toSignal(this.store.load$(), { initialValue: [] as Order[] });
```

---

## MUST NOT

- Introduce NgRx / Akita / Elf / Signals Store libraries without task scope when the repo has no such dependency.
- Use `effect()` to copy props into local state that `computed()` could derive.
- Mutate signal values from templates; mutate only in class methods / store actions.
- Mix uncontrolled `@Input()` and `input()` on the same component without a migration plan.
- Call `toSignal()` repeatedly inside methods that re-run every change detection cycle — create the bridge once at field init.
- Put remote cache invalidation logic only in components; prefer services/stores matching the repo.

---

## Prefer when matching repo

| Signal | Prefer |
|--------|--------|
| Existing NgRx / component-store | Extend that pattern; Signals for local UI only unless migrating |
| `providedIn: 'root'` stores | Keep singleton stores; feature `providers` when already scoped that way |
| RxJS-heavy services | Keep Observables at the boundary; convert at the component with `toSignal` / async pipe |
| Zoneless / experimental flags | Follow `angular.json` / bootstrap flags; do not toggle zoneless in a small fix |
| `linkedSignal` / resource APIs | Use only when the installed Angular version and repo already adopt them |
| Shared state across routes | Route data + services; URL for shareable state |

### State placement

| Kind | Where |
|------|--------|
| Ephemeral UI | Component `signal` / `computed` |
| Feature domain | Feature service / store |
| Cross-app session | Existing root store / auth service |
| Remote entities | HTTP service + `toSignal` / resource pattern already in repo |

### Input / output cheatsheet

| Need | API |
|------|-----|
| Required input | `input.required<T>()` |
| Optional with default | `input(defaultValue)` or `input<T>(undefined)` |
| Output event | `output<T>()` then `this.saved.emit(id)` |
| Two-way legacy | Prefer model signals only when the project already uses `model()` |

Do not mix decorator `@Input()` with `input()` on the same new public API surface without an explicit migration note in the PR.

---

## References

- [Angular — Signals](https://angular.dev/guide/signals)
- [Angular — Signal inputs](https://angular.dev/guide/components/inputs)
- [Angular — RxJS interop](https://angular.dev/guide/signals/rxjs-interop)
- [Angular best practices](https://angular.dev/best-practices)
