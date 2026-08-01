# Vue routing and state

Vue Router and Pinia (or legacy Vuex). Absorbs prior `vue-routing-state` stub. Detect libraries from `package.json`; do not add new state libraries without task scope.

---

## MUST

- Define routes in the project’s existing structure (`router/index.ts` or modular route files).
- Prefer **named routes** and `<router-link>` / `RouterLink` for internal navigation.
- Lazy-load route components with `() => import(...)` when neighboring routes already code-split.
- Keep route guards (`beforeEach`, per-route `beforeEnter`) thin — delegate auth/session checks to composables or stores.
- Prefer **Pinia** for new shared state: **one store per domain** (`useUserStore`, `useCartStore`).
- Declare Pinia `state` as a function; put derived data in `getters`; put async and mutations in `actions`.
- Do not mutate Pinia state outside actions (or the project’s documented patch helpers).
- Prefer route params/query for **shareable/bookmarkable** state; keep ephemeral UI (modals, panels) in component/local store unless the product requires deep links.

```typescript
{
  path: '/users/:id',
  name: 'user-detail',
  component: () => import('@/views/UserDetailView.vue'),
  props: true,
}
```

```typescript
export const useCartStore = defineStore('cart', {
  state: () => ({ items: [] as CartItem[] }),
  getters: {
    count: (s) => s.items.length,
  },
  actions: {
    async add(item: CartItem) {
      this.items.push(item);
    },
  },
});
```

---

## MUST NOT

- Introduce Redux, MobX, or a second Pinia pattern when Pinia is already standard.
- Migrate Vuex → Pinia inside a small feature PR unless explicitly requested.
- Put all app state in a single god store.
- Navigate via `window.location` for in-app routes.
- Store secrets or raw tokens in `localStorage` without following the project’s auth guidance.
- Encode entire feature trees in query strings when a store + route id is enough.

---

## Prefer when matching repo

| Signal | Prefer |
|--------|--------|
| Vuex modules present | Follow existing modules/actions/mutations |
| Nuxt | File-based routing, `navigateTo`, `useRoute`; Pinia via Nuxt module if present |
| SSR | Avoid browser-only APIs in stores without `import.meta.client` / `onMounted` guards |
| Persist plugins | Use existing `pinia-plugin-persistedstate` (or equivalent) config only |
| Router `createWebHistory` vs hash | Match current `createRouter` history mode |

### URL vs store

| Kind | Where |
|------|--------|
| Entity id / filters users share | Route params/query |
| Auth session | Existing auth store / cookies |
| Modal open, tab UI | Local ref / component state |
| Cart / draft domain | Domain Pinia store |

---

## References

- [Vue Router — Guide](https://router.vuejs.org/guide/)
- [Pinia — Introduction](https://pinia.vuejs.org/introduction.html)
- [Pinia — Defining a store](https://pinia.vuejs.org/core-concepts/)
- [Vue Router — Lazy loading](https://router.vuejs.org/guide/advanced/lazy-loading.html)
