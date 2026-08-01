# Vue reactivity

`ref`, `reactive`, `computed`, watchers, and shallow APIs for Vue 3. Keep side effects explicit; prefer derived state over mirrored copies.

---

## MUST

- Use **`ref`** for primitives and reassignable values; unwrap automatically in templates, use `.value` in script.
- Use **`computed`** for derived state — do not recompute the same expression in multiple template sites or duplicate into another ref via `watch`.
- Prefer **`watch`** with explicit sources over `watchEffect` when the dependency set should be obvious and narrow.
- Clean up watchers/subscriptions that create external listeners (return stop handles or dispose in `onUnmounted`).
- Use `shallowRef` / `shallowReactive` / `markRaw` for large non-reactive structures (chart instances, third-party class instances) when deep proxying is costly or harmful.
- Keep **UI state** separate from **server/async state**; do not copy query results into a ref “just to edit later” without a clear local draft model.
- Prefer readonly exposure from composables (`readonly(ref)`) when consumers must not mutate internal state.

```typescript
const query = ref('');
const items = ref<Item[]>([]);
const visible = computed(() =>
  items.value.filter((i) => i.name.includes(query.value)),
);

watch(query, (q) => {
  void loadSuggestions(q);
});
```

---

## MUST NOT

- Destructure `reactive` objects without `toRefs`/`toRef` if you still need reactivity on fields.
- Use `watchEffect` for async work without handling race/cancellation.
- Mutate `computed` getters’ dependencies inside the computed function.
- Deep-watch large trees by default (`watch(..., { deep: true })`) without need.
- Wrap every constant in `ref` — plain values are fine when never reactive.
- Rely on accidental reactivity of non-plain objects (Map/Set class instances) without checking Vue version behavior used by the project.

---

## Prefer when matching repo

| Signal | Prefer |
|--------|--------|
| Pinia stores | State in store; local refs for ephemeral UI only |
| VueUse already depended | Reuse `use*` utilities instead of reimplementing |
| Nuxt `useState` / `useAsyncData` | Prefer Nuxt primitives for SSR-safe state |
| Class instances / chart libs | `markRaw` / `shallowRef` as neighbors do |
| Form libraries (VeeValidate, FormKit) | Controlled fields via library APIs |

### Watch intent

| Intent | API |
|--------|-----|
| React to specific sources | `watch(source, cb)` |
| Auto-deps, sync only | `watchEffect` |
| Run once after flush | `watch(..., { flush: 'post' })` for DOM reads |

### Anti-pattern: mirrored state

```typescript
// Wrong — copies props into state that drifts
watch(
  () => props.item,
  (item) => {
    local.value = item;
  },
  { immediate: true },
);

// Prefer — derive or edit an explicit draft model
const draft = ref(structuredClone(props.item));
const title = computed(() => props.item.title);
```

Use a draft ref only when the user edits a snapshot; reset deliberately on prop identity change.

---

## References

- [Vue — Reactivity fundamentals](https://vuejs.org/guide/essentials/reactivity-fundamentals.html)
- [Vue — Computed and watch](https://vuejs.org/guide/essentials/computed.html)
- [Vue — Reactivity in depth](https://vuejs.org/guide/extras/reactivity-in-depth.html)
- [Vue — `shallowRef`](https://vuejs.org/api/reactivity-advanced.html#shallowref)
