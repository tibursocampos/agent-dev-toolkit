# React performance

Pragmatic performance for React and Next.js. Absorbs retired `react-performance.md`. Optimize only with evidence (Profiler, Lighthouse, Real User Monitoring). Do not confuse with RN list virtualization — see `react-native-guidelines/lists-and-performance.md` for mobile.

---

## MUST

- Measure before memoizing: use React DevTools Profiler and/or Lighthouse; document the bottleneck when changing hot paths.
- Default to simple components. Add `React.memo`, `useMemo`, and `useCallback` only when:
  - Profiling shows unnecessary re-renders of expensive subtrees, or
  - Referential stability is required for a memoized child or for Effect/deps contracts already in the code.
- Use **stable list keys** (entity IDs). Never use array index as `key` for mutable/filterable/sortable lists.
- On **Next.js App Router**: treat components as **Server Components by default**. Add `'use client'` only for interactivity, browser APIs, Hooks, and event handlers — not on every file “just in case.”
- Keep client bundles small: fetch and compose static structure on the server when RSC is in play; avoid importing server-only modules into client components.
- Parallelize independent fetches; avoid request waterfalls. Use Suspense/streaming when the project already does.
- Virtualize long DOM lists (`react-window`, `@tanstack/react-virtual`, or project equivalent) when node count hurts scroll/interaction.
- Lazy-load heavy client-only modules (charts, editors) with dynamic `import()` / `next/dynamic` as appropriate.
- Use the project image pipeline (`next/image` or equivalent) with dimensions to limit layout shift; lazy-load below-the-fold media.
- Prefer structural composition (splitting children so parents re-render less) before wrapping leaves in `memo`.

```tsx
// Prefer structural split so unrelated chrome does not re-render results
function Page({ filter }: { filter: string }) {
  return (
    <>
      <FilterBar value={filter} />
      <ExpensiveResults filter={filter} />
    </>
  );
}
```

Add `memo` only after Profiler shows `ExpensiveResults` re-rendering for unrelated parent updates **and** props are stable.

---

## MUST NOT

- Wrap every callback/value in `useCallback`/`useMemo` by reflex.
- Sprinkle `'use client'` across the tree when App Router + RSC are available and the file has no client-only needs.
- Optimize for Pages Router patterns inside an App Router app (or vice versa) without an explicit migration task.
- Add large dependencies without checking bundle impact (`@next/bundle-analyzer` or project equivalent).
- Prematurely micro-optimize renders when the cost is network or oversized assets.
- Use unstable keys (`Math.random()`, index on mutable lists) to “force refresh” — fix data identity instead.

---

## Prefer when matching repo

| Signal | Prefer |
|--------|--------|
| React Compiler enabled | Trust compiler memoization; manual memo only with residual evidence |
| React 19 without compiler | Still measure first; do not blanket-memo |
| TanStack Query / SWR | Rely on library cache/staleness; see `data-fetching.md` |
| Design system heavy trees | Memo at proven boundaries; do not memo every leaf |
| No Next.js (CRA/Vite SPA) | Skip RSC/`'use client'` rules; still apply memo/keys/bundle guidance |
| Route-level code split | Existing `React.lazy` / router lazy APIs before inventing new loaders |

### `'use client'` decision

| Needs | Directive |
|-------|-----------|
| Hooks, events, browser APIs | `'use client'` on the interactive leaf / boundary |
| Fetch + static markup only (App Router) | Server Component — no directive |
| Shared util imported by both | Keep pure; no client-only imports in shared server modules |

### Measurement checklist

- [ ] Profiler / Lighthouse before and after
- [ ] Confirmed cost is render vs network vs assets
- [ ] Memo/virtualization only where evidence points
- [ ] Bundle audit for new heavy deps

---

## References

- [React DevTools Profiler](https://react.dev/learn/react-developer-tools)
- [Next.js Server and Client Components](https://nextjs.org/docs/app/building-your-application/rendering/server-components)
- [web.dev performance](https://web.dev/performance/)
- [TanStack Virtual](https://tanstack.com/virtual/latest) (when virtualizing)
