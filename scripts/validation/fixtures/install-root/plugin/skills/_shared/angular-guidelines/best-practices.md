# AI-Agent Otimized Angular Best Practices

This document compiles guidelines and rule structures optimized specifically for LLMs and AI coding agents to ensure high-quality Angular generations, adapted from `alfredoperez/angular-best-practices`.

---

## 1. Modern Template Syntax

* Use the new **Control Flow Block** syntax (`@if`, `@for`, `@switch`) in templates instead of old directives (`*ngIf`, `*ngFor`):
  ```html
  <!-- Correct Control Flow -->
  @if (user(); as u) {
      <p>Welcome, {{ u.name }}</p>
  } @else {
      <p>Guest Session</p>
  }

  @for (item of items(); track item.id) {
      <li>{{ item.name }}</li>
  } @empty {
      <li>No items available</li>
  }
  ```

---

## 2. Dependency Injection (DI)

* Prefer using the `inject()` function in constructor-less classes for dependency injection. This maintains type inference and keeps component declarations clean:
  ```typescript
  // Correct
  export class OrderListComponent {
      private readonly orderService = inject(OrderService);
      private readonly route = inject(ActivatedRoute);
  }
  ```

---

## 3. Resource Cleanup and Subscription Management

* **Avoid Memory Leaks:** Never leave open RxJS subscriptions inside components.
* **Auto-unsubscribe:** Use the `takeUntilDestroyed()` operator when subscribing to Observables in constructors or initializer blocks:
  ```typescript
  export class DashboardComponent {
      constructor() {
          inject(NotificationService).messages$
              .pipe(takeUntilDestroyed())
              .subscribe(msg => this.handleMessage(msg));
      }
  }
  ```
* **Async Pipe / Signals:** Whenever possible, resolve template observables using the `async` pipe or convert them to signals with `toSignal()` to let the framework manage cleanups.

---

## 4. Standalone Import Validation

* Before writing templates, verify that all directives and child components used in the template are explicitly declared in the component's `@Component.imports` array.
