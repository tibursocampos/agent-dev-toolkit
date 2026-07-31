# React Performance

Pragmatic performance guidance for React and Next.js apps. Concepts adapted from Vercel agent-skills guidance - apply only when profiling shows a real issue.

## Composition over premature memoization

- Default to simple components; add `React.memo`, `useMemo`, and `useCallback` only when:
  - Profiling shows unnecessary re-renders, or
  - Referential stability is required for child memoization or effect deps.
- Do not wrap every callback in `useCallback` by reflex.

## Server Components (Next.js App Router)

When the project uses React Server Components:

- **Server by default** - fetch data and render static structure on the server.
- **`'use client'`** only for interactivity, browser APIs, hooks, and event handlers.
- Do not import server-only modules into client components.
- Keep client bundles small - push data fetching to Server Components or route handlers.

## Data fetching

- Colocate fetching with the component that needs data (RSC) or use established data libraries (React Query, SWR) per project.
- Avoid waterfall requests - parallelize independent fetches.
- Stream with Suspense boundaries when the project already uses streaming.

## Lists and virtualization

- Stable `key` props (IDs, not array index for mutable lists).
- Virtualize long lists (`react-window`, `@tanstack/react-virtual`) when DOM node count hurts scroll performance.

## Images and assets

- Use Next.js `Image` or project image pipeline when available.
- Lazy-load below-the-fold media; specify dimensions to reduce layout shift.

## Bundle size

- Dynamic `import()` for heavy client-only modules (charts, editors).
- Audit with `@next/bundle-analyzer` or project equivalent before adding large dependencies.

## Measurement

- Use React DevTools Profiler and Lighthouse before optimizing.
- Document before/after metrics when making performance changes.
