# TypeScript clean code

Guidelines for type-safe, maintainable TypeScript, adapted from clean-code-typescript themes. Pair with `typescript-strict.md` and `google-ts-style.md`.

---

## MUST

- Maintain `"strict": true`; do not introduce implicit `any` on new code.
- Prefer `unknown` + type guards over `any` for untrusted or dynamic values.
- Use `interface` for extensible object shapes / class contracts; use `type` for unions, intersections, tuples, and mapped compositions — match neighbor style when the repo standardizes on one.
- Declare class member visibility explicitly (`public` / `private` / `protected`) when using classes.
- Prefer `readonly` for constructor-injected dependencies and immutable fields.
- Implement type predicates (`value is T`) for reusable narrowing.
- Keep identifiers and comments in **English**; no `I`-prefix on interfaces unless the repo already uses that legacy style.

---

## MUST NOT

- Use non-null assertions (`!`) to bypass null checks as a habit.
- Prefix interfaces with `I` on new APIs when neighbors use plain nouns (`UserRepository`, not `IUserRepository`).
- Over-abstract with deep generic hierarchies for a single call site.
- Mutate function parameters when a new object/array is clearer and neighbors avoid mutation.
- Leave `TODO` type escapes (`as unknown as T`) without a tracked follow-up.
- Duplicate the same structural type under many names in one feature — reuse.

---

## Prefer when matching repo

### Interfaces vs type aliases

```typescript
interface User {
  id: string;
  name: string;
}

type AuthenticationStatus = 'authenticated' | 'unauthenticated' | 'loading';
```

### Classes

```typescript
class OrderService {
  constructor(private readonly repository: OrderRepository) {}
}
```

- Prefer functions + modules over classes when the project is functional-first.
- Prefer DI patterns already present (constructor injection, factory, tsyringe/inversify/Nest) — do not add a DI container without ask.

### Generics and guards

```typescript
function isApiError(error: unknown): error is ApiError {
  return typeof error === 'object' && error !== null && 'statusCode' in error;
}
```

| Topic | Prefer |
|-------|--------|
| Generic names | `TResult`, `TEntity` when single-letter `T` is unclear |
| Discriminated unions | `kind` / `type` field for state machines |
| Exhaustiveness | `switch` + `never` assert in default |
| Result types | Match existing `Result`/`Either` utilities — do not invent a second |

### Functions

- Small, single-purpose functions; early returns over deep nesting.
- Prefer `async/await` with typed rejections handled at boundaries (`node-structure-errors.md` for HTTP).

---

## References

- [TypeScript Handbook — Object Types](https://www.typescriptlang.org/docs/handbook/2/objects.html)
- [TypeScript Handbook — Generics](https://www.typescriptlang.org/docs/handbook/2/generics.html)
- [labs42io/clean-code-typescript](https://github.com/labs42io/clean-code-typescript)
- [TypeScript ESLint — Recommended](https://typescript-eslint.io/getting-started/)
