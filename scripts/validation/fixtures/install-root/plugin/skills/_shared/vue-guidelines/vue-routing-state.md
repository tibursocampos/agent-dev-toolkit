# Vue Routing and State

Detect Vue Router and Pinia (or Vuex) from the project; do not add new state libraries without task scope.

## Vue Router

- Define routes in the project's existing structure (`router/index.ts` or modular route files).
- Use named routes and `router-link` for navigation.
- Lazy-load route components with dynamic `import()` for code splitting when the project already does so.
- Route guards (`beforeEach`) for auth - keep async logic minimal; delegate to composables or stores.

```typescript
{
  path: '/users/:id',
  name: 'user-detail',
  component: () => import('@/views/UserDetailView.vue'),
  props: true,
}
```

## Pinia (preferred for new state)

- One store per domain (`useUserStore`, `useCartStore`).
- `state` as a function; `getters` for derived data; `actions` for async and mutations.
- Do not mutate state outside actions.
- Reset store state in tests via `$reset()` when available.

## Vuex (legacy projects)

- Follow existing module structure; do not migrate to Pinia unless the task requires it.
- Use actions for async; mutations for synchronous commits.

## URL and state sync

- Prefer route params/query for shareable/bookmarkable state.
- Ephemeral UI state (modals, panels) stays in component or local store - not in URL unless required.

## SSR / Nuxt

When `nuxt.config` exists, follow Nuxt conventions (`useRoute`, `useFetch`, file-based routing) - do not fight the framework.
