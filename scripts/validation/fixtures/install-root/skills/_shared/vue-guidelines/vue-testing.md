# Vue Testing

Vitest + Vue Test Utils unless the project uses Jest. Follow `frontend-guidelines/frontend-testing.md` for structure.

## Component tests

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

## Querying

- Prefer `getByRole`, `getByLabelText` patterns via DOM queries or Test Utils `get` with accessible selectors.
- Use `data-testid` only when roles/labels are insufficient.

## Pinia in tests

- Create a fresh pinia instance per test (`createPinia()` + `setActivePinia`).
- Stub actions when testing components in isolation.

## Router in tests

- Use `createRouter` with memory history or stub `useRoute` / `useRouter` per project test helpers.

## Async

- `await flushPromises()` or `await wrapper.vm.$nextTick()` after state changes.
- Mock `fetch` / HTTP clients at the composable or service boundary.

## Commands

```bash
npm test
npm run build
vue-tsc --noEmit
```
