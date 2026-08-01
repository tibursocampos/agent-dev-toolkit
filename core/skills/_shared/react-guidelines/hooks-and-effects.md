# React hooks and effects

Rules of Hooks, derived state, and Effect discipline. Pair with `components-and-state.md` and `data-fetching.md`. Primary source: React docs *You Might Not Need an Effect*.

---

## MUST

- Call Hooks only at the top level of React function components or custom Hooks — never inside loops, conditions, or nested helpers.
- Call Hooks only from React functions (components / custom Hooks), not from plain utilities or class methods.
- Name custom Hooks `use*` and compose primitives (`useState`, `useEffect`, `useRef`, …) behind a capability name (`useCart`, `useAuthSession`).
- Prefer **calculating during render** when the next value depends only on props/state already available.
- Prefer **event handlers** for user-driven updates (submit, click, change). Do not route every click through an Effect that watches a flag.
- Reset state with a **`key`** on the component when the identity of the edited entity changes, instead of Effects that clear fields on `id` change when that fits the UX.
- Declare complete Effect dependency arrays; fix missing deps by restructuring (derived values, event handlers, or extracting child components), not by casually disabling the lint rule.
- Clean up subscriptions, timers, and listeners in the Effect cleanup function.
- Keep Effects for **synchronizing with an external system** (DOM APIs not managed by React, network when no query library, third-party widgets) — not for chaining React state updates.
- Prefer adjusting state during render only for the rare “store previous + adjust” patterns documented by React — default to derivation and events first.

```tsx
// Wrong - Effect state → state
const [fullName, setFullName] = useState('');
useEffect(() => {
  setFullName(`${firstName} ${lastName}`);
}, [firstName, lastName]);

// Right - derived in render
const fullName = `${firstName} ${lastName}`;
```

```tsx
// Wrong - Effect after click flag
useEffect(() => {
  if (submitted) postForm(data);
}, [submitted, data]);

// Right - event handler
async function handleSubmit() {
  await postForm(data);
}
```

---

## MUST NOT

- Use an Effect solely to update state from other state/props when a render-time derivation or event handler works (classic “you might not need an Effect”).
- Call Hooks conditionally (`if (x) useFoo()`), after an early `return`, or inside `useMemo`/`useCallback` factories.
- Suppress `react-hooks/exhaustive-deps` without a documented reason and a safer structure nearby.
- Fetch in Effects by default when the project already uses RSC, route loaders, TanStack Query, or SWR — follow `data-fetching.md`.
- Put non-idempotent work in render (network, random writes); use events or Effects with proper guards.
- Chain Effects that only transform state A → state B → state C; collapse into derivation or a reducer.

---

## Prefer when matching repo

| Signal | Prefer |
|--------|--------|
| React Compiler / React 19 auto-memo in use | Avoid reflexive `useMemo`/`useCallback`; see `performance.md` |
| Existing custom Hook layer | Extend those Hooks; do not invent a parallel `hooks/` style |
| Forms library (RHF, Formik) | Use library field APIs; avoid Effect syncing form ↔ state |
| Strict Mode double-invoke | Ensure Effects are resilient (cleanup + abort); do not “fix” by removing Strict Mode |
| Third-party widget (charts, maps) | One Effect to mount/update/destroy; keep React state as the source of truth |

### Decision cheatsheet

| Need | Prefer |
|------|--------|
| Value from props/state | Derive in render |
| Update because user did X | Event handler |
| Sync with external system | `useEffect` (+ cleanup) |
| Data from server | Query lib / RSC / loader (`data-fetching.md`) |
| Adjust state when prop identity changes | `key` remount or controlled pattern |
| Complex interdependent local fields | `useReducer` instead of Effect chains |

### Custom Hook shape

- Input: props / ids / options the caller already has
- Output: values + handlers the UI needs (not the whole query client)
- Side effects: owned inside the Hook with cleanup; UI stays free of Effect boilerplate

---

## References

- [Rules of Hooks](https://react.dev/reference/rules/rules-of-hooks)
- [You Might Not Need an Effect](https://react.dev/learn/you-might-not-need-an-effect)
- [Synchronizing with Effects](https://react.dev/learn/synchronizing-with-effects)
- [Removing Effect dependencies](https://react.dev/learn/removing-effect-dependencies)
