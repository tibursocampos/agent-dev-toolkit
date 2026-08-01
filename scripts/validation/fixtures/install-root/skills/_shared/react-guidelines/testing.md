# React testing (web)

Behavior-focused tests for React DOM apps. Hub practices: `frontend-guidelines/frontend-testing.md`. Use this file for React Testing Library (RTL) specifics. For mobile, use `react-native-guidelines/testing.md` (RNTL — not this file).

---

## MUST

- Prefer **React Testing Library** (`@testing-library/react`) + **user-event** (`@testing-library/user-event`) for component interaction tests when the repo uses Jest/Vitest + RTL.
- Query by **accessible role and name** first: `getByRole`, then `getByLabelText` / `getByPlaceholderText`, then text. Use `getByTestId` only as a last resort when the repo already relies on test ids.
- Assert **user-visible behavior** (text, roles, disabled, focus, navigation side effects exposed in UI) — not internal state, private methods, or implementation details.
- Structure tests with `// Arrange`, `// Act`, `// Assert` when that is the project convention; name tests `should_<result>_when_<condition>` (or the repo’s equivalent).
- Cover the changed flow: happy path, empty/error UI touched by the change, and critical a11y affordances (label/role) for interactive controls.
- Prefer integration-style component tests for real flows; keep pure logic in small unit tests under existing TestInfrastructure / test-utils — do not duplicate arrange builders in every file.
- Await async UI with `findBy*` / `waitFor` as appropriate; wrap user interactions with `userEvent.setup()`.
- Prefer `screen` queries after `render`; clean up is automatic with modern RTL + Jest/Vitest.

```tsx
// Arrange
const user = userEvent.setup();
const onSubmit = vi.fn();
render(<LoginForm onSubmit={onSubmit} />);

// Act
await user.type(screen.getByRole('textbox', { name: /email/i }), 'a@b.co');
await user.click(screen.getByRole('button', { name: /sign in/i }));

// Assert
expect(onSubmit).toHaveBeenCalled();
```

---

## MUST NOT

- Import **React Native** Testing Library APIs into web tests (or DOM RTL into RN tests).
- Default to shallow Enzyme / snapshot-only coverage with no behavior assertion.
- Select elements primarily via CSS class chains or brittle DOM structure.
- Hit real network in unit/component tests without the project’s MSW / mock harness.
- Assert on `useState` values, Redux store internals, or hook private returns unless the repo already tests hooks via a documented pattern (`renderHook`).
- Use `fireEvent` as the default interaction API when `user-event` is available — prefer user-event for closer browser behavior.

---

## Prefer when matching repo

| Signal | Prefer |
|--------|--------|
| Jest vs Vitest | Use the configured runner and RTL adapter |
| MSW / mock service worker | Reuse handlers; do not invent a second mock HTTP layer |
| Cypress / Playwright for E2E | Keep RTL for component behavior; E2E for critical journeys only |
| Blip / web components | Follow `blip-guidelines/` (often Cypress component) when BDS requires it |
| Shared fixtures | Centralize under TestInfrastructure / `test-utils` — no copy-paste arrange |
| React Query / SWR | Wrap with existing `QueryClientProvider` / SWR config test helpers |

### Query priority (RTL)

1. `getByRole` (+ accessible name)
2. `getByLabelText` / `getByPlaceholderText`
3. `getByText` / `getByDisplayValue`
4. `getByTestId` (escape hatch)

### What to cover vs skip

| Cover | Usually skip |
|-------|----------------|
| Submit, validation messages, disabled rules | Private helpers already unit-tested |
| Loading → success / error text | Third-party DS internals |
| Role/name regressions on new controls | Pixel-perfect CSS |

### Anti-pattern examples

```tsx
// Avoid
container.querySelector('.btn-primary-xyz');
expect(wrapper.state('open')).toBe(true);

// Prefer
expect(screen.getByRole('dialog', { name: /settings/i })).toBeInTheDocument();
```

---

## References

- [React Testing Library](https://testing-library.com/docs/react-testing-library/intro/)
- [Guiding Principles](https://testing-library.com/docs/guiding-principles/)
- [user-event](https://testing-library.com/docs/user-event/intro/)
- [Common mistakes with React Testing Library](https://kentcdodds.com/blog/common-mistakes-with-react-testing-library)
