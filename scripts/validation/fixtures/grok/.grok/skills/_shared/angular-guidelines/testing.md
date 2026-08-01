# Angular testing

Behavior-focused tests for Angular components, services, and routes. Prefer the project’s runner (Karma/Jasmine or Jest/Vitest via builder). Shared frontend testing habits live in `frontend-guidelines/frontend-testing.md`.

---

## MUST

- Structure tests with **Arrange / Act / Assert** (comments when the repo uses them).
- Assert **user-visible behavior** (DOM text, roles, emitted outputs, navigations) — not private fields or change-detection implementation details.
- Use `TestBed` (or project helper) to configure standalone imports / providers for the SUT.
- Prefer `HttpClientTestingModule` / `provideHttpClientTesting` for HTTP; never hit real networks in unit tests.
- Create fresh TestBed state per file/suite per project norms; reset stubs between tests when they mutate.
- Cover new or changed behavior with at least one focused test; prefer shallow component tests plus service unit tests over one giant E2E for every branch.
- Use stable queries: roles/labels/text; `data-testid` only when accessibility queries are insufficient.
- Name tests in English matching repo style (`should … when …` or equivalent).

```typescript
it('should emit saved when form is valid', () => {
  // Arrange
  const fixture = TestBed.createComponent(OrderEditComponent);
  const component = fixture.componentInstance;
  fixture.detectChanges();
  component.form.setValue({ code: 'ORD-1' });

  // Act
  component.submit();

  // Assert
  expect(/* output or service call */).toHaveBeenCalled();
});
```

---

## MUST NOT

- Snapshot entire component HTML as the only assertion for interactive behavior.
- Assert on private members (`component['privateField']`) when a public API or DOM outcome exists.
- Share mutable TestBed overrides across unrelated specs without reset.
- Write tests that only increase coverage lines without asserting behavior.
- Duplicate large arrange blocks — extract fixtures under the project’s test helpers / `*-fake` patterns.
- Disable `teardown` / leave async timers hanging.

---

## Prefer when matching repo

| Signal | Prefer |
|--------|--------|
| Jasmine + Karma | `describe` / `it` / `spyOn`; match `angular.json` test target |
| Jest / Vitest builder | Match existing `*.spec.ts` patterns and jest-preset-angular (or equivalent) |
| Spectator / Testing Library | Use project wrappers instead of inventing a parallel harness |
| Cypress / Playwright e2e | Reserve for critical flows; keep unit/integration cheaper |
| Signals components | Read signals via public API / fixture detectChanges; avoid brittle internal effect timing |
| Router testing | `RouterTestingModule` / `provideRouter` with test routes already used nearby |

### What to test where

| Layer | Focus |
|-------|--------|
| Service | Mapping, error handling, HTTP contract with mocking controller |
| Component | Template bindings, outputs, form validation UX |
| Guard / interceptor | Allow/deny and header behavior with mocked deps |
| Smoke e2e | Login → primary happy path only when required |

### Standalone TestBed sketch

```typescript
await TestBed.configureTestingModule({
  imports: [OrderListComponent],
  providers: [
    provideHttpClient(),
    provideHttpClientTesting(),
    { provide: OrderService, useValue: orderServiceStub },
  ],
}).compileComponents();
```

Match the project’s `provide*` vs `*TestingModule` style. Prefer overriding only the collaborators the scenario needs.

---

## References

- [Angular — Testing](https://angular.dev/guide/testing)
- [Angular — Testing services](https://angular.dev/guide/testing/services)
- [Angular — Testing components](https://angular.dev/guide/testing/components-basics)
- [Testing Library — Guiding principles](https://testing-library.com/docs/guiding-principles)
