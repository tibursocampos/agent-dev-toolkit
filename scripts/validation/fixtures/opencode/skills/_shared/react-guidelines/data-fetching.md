# React data fetching

Server/async data for React web apps. Complements `components-and-state.md` (UI vs server state) and `hooks-and-effects.md` (no Effect-for-fetch by default).

---

## MUST

- Treat remote data as **server/async state**: caching, revalidation, retries, and mutations belong in the project’s data layer (RSC/fetch, route loaders, TanStack Query, SWR, RTK Query) — not ad-hoc `useState` + `useEffect` copies of the payload.
- Colocate fetching with the owner that needs the data: **Server Components / route handlers** on App Router when available; otherwise feature hooks/services already used in the repo.
- Model **loading, error, empty, and success** UI explicitly for user-facing views touched by the change.
- Deduplicate and share cache via the library’s keys/query keys; invalidate or update cache after mutations using the project’s established pattern.
- Parallelize independent requests; avoid sequential waterfalls when data has no dependency.
- Abort or ignore stale responses (AbortController, query cancellation, `ignore` flags) when fetching from Effects is unavoidable.
- Keep secrets and privileged tokens off the client; call authenticated backends through existing BFF/route handlers when that is the architecture.
- Prefer mutations that update cache optimistically only when the project already does — otherwise invalidate/refetch consistently.

```tsx
// Prefer query library over Effect + useState mirror
const { data, isPending, isError } = useQuery({
  queryKey: ['user', userId],
  queryFn: () => userApi.get(userId),
});
```

```tsx
// Avoid
const [user, setUser] = useState(null);
useEffect(() => {
  let cancelled = false;
  userApi.get(userId).then((u) => {
    if (!cancelled) setUser(u);
  });
  return () => {
    cancelled = true;
  };
}, [userId]);
```

---

## MUST NOT

- Mirror TanStack Query / SWR / RSC results into local `useState` “so the component owns it,” then sync with Effects.
- Fetch in `useEffect` on every mount when the project already standardizes on Query/SWR/RSC/loaders.
- Introduce a second data library (e.g. add SWR beside existing React Query) in a small feature.
- Put API keys or long-lived secrets in client bundles or public env (`NEXT_PUBLIC_*` only for truly public config).
- Block the whole page on independent sections when Suspense/streaming or partial render is already in use.
- Fire duplicate fetches from parent and child for the same resource without shared cache.

---

## Prefer when matching repo

| Signal | Prefer |
|--------|--------|
| Next.js App Router + RSC | `fetch` on server / `async` Server Components; `'use client'` only for interactive islands (`performance.md`) |
| TanStack Query / React Query | Hooks + query keys + mutations; match existing `QueryClient` setup |
| SWR | `useSWR` / `mutate` patterns already in tree |
| RTK Query / Apollo | Extend slices/documents; do not add parallel REST client for same resources |
| SPA without query lib | Thin `services/` + one Hook pattern; still separate UI state from remote state |
| Blip / iframe plugins | Resource commands vs external REST per `blip-guidelines/` |
| Auth cookies / BFF | Existing API client interceptors; no ad-hoc token in `localStorage` if forbidden |

### UI vs server state (quick)

| Kind | Examples | Tooling |
|------|----------|---------|
| UI | modal open, draft input, selected tab | `useState` / `useReducer` |
| Server | user profile, lists, permissions | Query/SWR/RSC/loader |

### Query key / cache habits

- Keys: stable tuples including entity id + filters that change the result
- Mutations: invalidate related keys or update cache via project helpers
- Errors: map to user-visible messages; do not swallow silently

### Waterfall vs parallel

| Pattern | When |
|---------|------|
| Parallel `Promise.all` / multiple queries | Independent resources |
| Sequential | Second request needs first’s id/token |
| Suspense boundaries | Project already streams sections independently |

---

## References

- [TanStack Query](https://tanstack.com/query/latest/docs/framework/react/overview)
- [SWR](https://swr.vercel.app/)
- [Next.js Data Fetching](https://nextjs.org/docs/app/building-your-application/data-fetching)
- [You Might Not Need an Effect (data fetching)](https://react.dev/learn/you-might-not-need-an-effect#fetching-data)
