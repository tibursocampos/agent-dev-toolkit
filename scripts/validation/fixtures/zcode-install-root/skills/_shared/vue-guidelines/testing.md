# Vue testing

Vitest + Vue Test Utils unless the project uses Jest. Absorbs prior `vue-testing` stub. Follow `frontend-guidelines/frontend-testing.md` for cross-stack structure.

---

## MUST

- Structure tests with **Arrange / Act / Assert**.
- Assert **behavior** (emitted events, visible text, roles) — not private setup internals.
- Prefer accessible queries (`getByRole`, label text) via DOM or Testing Library when the project uses it; otherwise Test Utils `get` with stable selectors.
- Use `data-testid` only when roles/labels are insufficient.
- Create a **fresh Pinia** per test (`createPinia()` + `setActivePinia`) when stores are involved.
- Stub or mock HTTP at the composable/service boundary — no real network in unit tests.
- `await` flushes (`flushPromises`, `$nextTick`) after state changes that update the DOM.
- Name tests in English matching repo style.

```typescript
import { mount } from '@vue/test-utils';
import { describe, it, expect } from 'vitest';
import UserCard from './UserCard.vue';

describe('UserCard', () => {
  it('emits save when button clicked', async () => {
    // Arrange
    const wrapper = mount(UserCard, { props: { userId: '1', name: 'Ada' } });

    // Act
    await wrapper.get('[data-testid="save"]').trigger('click');

    // Assert
    expect(wrapper.emitted('save')).toEqual([['1']]);
  });
});
```

---

## MUST NOT

- Snapshot entire SFCs as the only proof of interactive behavior.
- Share one mutated Pinia instance across unrelated tests.
- Assert on implementation details of composables when a public return value exists.
- Leave timers/promises dangling (use fake timers when the project does).
- Duplicate arrange blocks — centralize fixtures under test helpers / factories.

---

## Prefer when matching repo

| Signal | Prefer |
|--------|--------|
| Vitest | `vitest` + `@vue/test-utils`; match `vitest.config` |
| Jest | Keep Jest; do not add Vitest in a small PR |
| Vue Testing Library | Prefer role queries over CSS classes |
| Playwright / Cypress | Critical flows only |
| Router | Memory history `createRouter` or stub `useRoute` / `useRouter` via project helpers |

### What to test where

| Layer | Focus |
|-------|--------|
| Composable | Returned state transitions, error paths |
| Component | Rendering, emits, disabled/loading UX |
| Store | Actions/getters with mocked APIs |
| E2E smoke | One primary happy path when required |

### Commands

```bash
npm test
npm run build
vue-tsc --noEmit
```

---

## References

- [Vue Test Utils](https://test-utils.vuejs.org/)
- [Vitest — Vue](https://vitest.dev/guide/features.html)
- [Pinia — Testing](https://pinia.vuejs.org/cookbook/testing.html)
- [Testing Library — Guiding principles](https://testing-library.com/docs/guiding-principles)
