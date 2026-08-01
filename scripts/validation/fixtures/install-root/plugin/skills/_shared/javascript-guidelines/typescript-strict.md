# TypeScript Strict Mode

Apply when the project uses TypeScript. Match `tsconfig.json` strictness; do not weaken compiler options.

## Strict compiler options

Prefer enabled in project `tsconfig`:

- `strict: true` (includes `strictNullChecks`, `noImplicitAny`, etc.)
- `noUncheckedIndexedAccess` when the project already uses it
- `exactOptionalPropertyTypes` when enabled

Fix types at the source; avoid `as any` and `@ts-ignore` except documented edge cases.

## Utility types

Use built-in utilities before inventing custom types:

- `Partial<T>`, `Required<T>`, `Pick<T, K>`, `Omit<T, K>`
- `Record<K, V>` for string-keyed maps
- `ReturnType<F>`, `Parameters<F>` for function inference

## Branded types

For domain IDs and units, use branded types to prevent accidental mixing:

```typescript
type UserId = string & { readonly __brand: 'UserId' };
```

Only when the project or API layer already uses this pattern.

## Module boundaries

- **Barrel files** (`index.ts`): use sparingly; avoid circular re-exports.
- **Public API**: export only what consumers need from feature modules.
- **Side effects**: isolate in entry files; keep modules pure where possible.

## Null and undefined

- Prefer explicit `| null` or optional `?` over loose checks.
- Use nullish coalescing (`??`) and optional chaining (`?.`) idiomatically.
- Narrow types with type guards before access.

## Async types

- Return `Promise<T>` from async functions; avoid `Promise<any>`.
- Type `fetch` responses and parse results before use.
