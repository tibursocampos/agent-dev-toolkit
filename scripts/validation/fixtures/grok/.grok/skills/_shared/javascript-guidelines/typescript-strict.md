# TypeScript strict mode

Apply when the project uses TypeScript. Match `tsconfig.json` strictness; do not weaken compiler options. Pair with `clean-code-ts.md` and `google-ts-style.md`.

---

## MUST

- Keep `"strict": true` (and project-enabled strict flags) intact — fix types at the source.
- Prefer explicit types on public exports and ambiguous boundaries (API DTOs, shared libs).
- Use built-in utility types (`Partial`, `Required`, `Pick`, `Omit`, `Record`, `ReturnType`, `Parameters`) before inventing one-off mapped types.
- Narrow `unknown` with type guards before property access; type `fetch`/HTTP parse results before use.
- Return `Promise<T>` from async functions with a concrete `T` — not `Promise<any>`.
- Prefer `??` and `?.` for nullish handling; make `| null` vs optional `?` intentional.
- Keep type names and comments in **English**.

---

## MUST NOT

- Introduce `as any`, `@ts-ignore`, or `@ts-nocheck` except documented, scoped edge cases with a reason.
- Weaken `strictNullChecks`, `noImplicitAny`, or related flags to land a feature.
- Use non-null assertions (`!`) as a default escape — narrow or redesign instead.
- Export wide `any`-typed public APIs from feature modules.
- Create circular barrel re-exports that break builds or hide dependency direction.
- Mix unchecked JSDoc `@type` hacks with strict TS in new code when `.ts` is available.

---

## Prefer when matching repo

| Flag / pattern | Prefer |
|----------------|--------|
| `noUncheckedIndexedAccess` | Handle `T \| undefined` on index reads when already enabled |
| `exactOptionalPropertyTypes` | Distinguish missing vs `undefined` when enabled |
| Branded ids | `type UserId = string & { readonly __brand: 'UserId' }` only if neighbors use brands |
| Barrels `index.ts` | Sparse; export only the public surface consumers need |
| `unknown` vs `any` | `unknown` + guards for external data |
| Enums | Prefer union string literals when the project already does; keep `enum` if ubiquitous |

### Strict baseline

```json
{
  "compilerOptions": {
    "strict": true
  }
}
```

Add project-specific flags only when already present or explicitly requested.

### Narrowing sketch

```typescript
function isApiError(error: unknown): error is { statusCode: number; message: string } {
  return (
    typeof error === 'object' &&
    error !== null &&
    'statusCode' in error &&
    'message' in error
  );
}
```

### Module boundaries

- Side effects belong in entry files (`main.ts`, `server.ts`); keep importable modules free of listen/connect side effects when neighbors are pure.
- Prefer path aliases already in `tsconfig` (`@/`) over deep `../../` chains when configured.

### Checklist before handoff

- [ ] `tsc --noEmit` (or project typecheck script) clean on touched packages
- [ ] No new `any` / `@ts-ignore` without coded reason
- [ ] External JSON parsed into typed results (zod/io-ts/manual guards — match repo)
- [ ] Optional props and `null` modeled intentionally under project flags
- [ ] Public exports have stable, exported types (not only inferred opaque blobs)

### `unknown` at boundaries

```typescript
async function readUser(json: unknown): Promise<User> {
  if (!isUser(json)) {
    throw new Error('Invalid user payload');
  }
  return json;
}
```

---

## References

- [TypeScript — TSConfig Reference (strict)](https://www.typescriptlang.org/tsconfig/#strict)
- [TypeScript — Utility Types](https://www.typescriptlang.org/docs/handbook/utility-types.html)
- [TypeScript — Narrowing](https://www.typescriptlang.org/docs/handbook/2/narrowing.html)
- [TypeScript — Module Resolution](https://www.typescriptlang.org/docs/handbook/modules/introduction.html)
