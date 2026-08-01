# React Native / Expo testing

Behavior-focused tests for RN and Expo. Prefer **React Native Testing Library (RNTL)** — not DOM React Testing Library.

---

## MUST

- Use **`@testing-library/react-native`** (RNTL) with Jest (Expo/RN default) or the project’s configured Vitest/Jest setup.
- Query by **accessible role / text / label** first; avoid implementation details and native host internals.
- Drive interactions with RNTL’s `userEvent` (or project-supported fireEvent patterns) — assert user-visible outcomes.
- Cover changed screens/flows: render + events, empty/error list states, and navigation params / guards when routing changes.
- Mock native modules at the boundary; do not hit real device APIs, camera, or push in unit tests.
- Prefer integration-style component tests for real flows; keep pure logic in small unit tests with shared fixtures (TestInfrastructure / test-utils).
- Name tests `should_<result>_when_<condition>` (or repo equivalent); use `// Arrange`, `// Act`, `// Assert` when the repo does.
- Ensure interactive controls under test have `accessibilityLabel` / role so queries stay stable (`accessibility.md`).

```tsx
import { render, screen, userEvent } from '@testing-library/react-native';

test('should_submit_when_form_valid', async () => {
  // Arrange
  const user = userEvent.setup();
  const onSubmit = jest.fn();
  render(<LoginScreen onSubmit={onSubmit} />);

  // Act
  await user.type(screen.getByLabelText(/email/i), 'a@b.co');
  await user.press(screen.getByRole('button', { name: /sign in/i }));

  // Assert
  expect(onSubmit).toHaveBeenCalled();
});
```

---

## MUST NOT

- Import **web** `@testing-library/react` / DOM APIs into RN tests (or RNTL into web tests).
- Snapshot-only coverage with no behavior assertions.
- Call real network / device services without an explicit integration harness.
- Assert on private component state or native fiber internals.
- Duplicate provider wrappers in every file when `renderWithProviders` exists.

---

## Prefer when matching repo

| Layer | Prefer (greenfield / when free) |
|-------|----------------------------------|
| Runner | Jest (Expo/RN default) or project Vitest |
| Components | RNTL (`@testing-library/react-native`) |
| Navigation | Wrap with the project’s test navigation helpers if present |
| Native modules | Jest mocks / Expo mock APIs already used in the repo |

| Signal | Prefer |
|--------|--------|
| Maestro / Detox / E2E | Keep RNTL for components; E2E for critical device journeys |
| Shared render helpers | Reuse `renderWithProviders` — do not fork per test file |
| Expo Router | Official testing helpers / existing wrap patterns |

### What to cover

- Screen/component behavior for changed flows (render + user events)
- Navigation params / route guards when the change touches routing
- Platform-specific branches when both sides matter (`Platform.OS`)
- Error and empty states for lists and forms touched in the change

### Commands (project-equivalent)

```bash
npm test
```

Add typecheck/lint only when configured (`tsc`, `expo lint`, ESLint). Prefer CI scripts already listed in `package.json`.

### Anti-patterns

```tsx
// Avoid - web RTL in RN project
import { render } from '@testing-library/react';

// Avoid - no behavior
expect(tree).toMatchSnapshot();
```

---

## References

- [React Native Testing Library](https://callstack.github.io/react-native-testing-library/)
- [Expo testing](https://docs.expo.dev/develop/unit-testing/)
- [Jest](https://jestjs.io/docs/getting-started)
- [Guiding Principles (Testing Library)](https://testing-library.com/docs/guiding-principles/)
