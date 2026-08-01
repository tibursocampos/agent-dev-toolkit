# TypeScript Clean Code Guidelines

This document outlines core guidelines for writing type-safe, maintainable, and clean TypeScript code, adapted from `labs42io/clean-code-typescript`.

---

## 1. Type Safety and Configurations

* **Strict Mode:** Maintain `"strict": true` in `tsconfig.json`. Ensure no implicit `any` types are introduced.
* **Avoid `any`:** Do not use `any` as a type wildcard. If a type is unknown or dynamic, use `unknown` and implement type guards (e.g. `typeof`, `instanceof`, or custom type assertions).
* **Avoid Non-Null Assertion Operator (`!`):** Avoid using `!` to bypass compiler checks. Instead, use optional chaining (`?.`) or explicit null checks.

---

## 2. Interfaces and Type Aliases

* **Interfaces for Objects and Classes:** Prefer `interface` for declaring object shapes that are extensible or implemented by classes.
* **Type Aliases for Unions and Intersections:** Use `type` for unions, intersections, primitives, tuples, or complex functional signatures.
  ```typescript
  // Interfaces are extendable
  interface User {
      id: string;
      name: string;
  }

  // Types are for composition
  type AuthenticationStatus = "authenticated" | "unauthenticated" | "loading";
  ```
* **Naming:** Do not prefix interfaces with `I`. Use plain nouns (e.g., `UserRepository`, not `IUserRepository`).

---

## 3. Classes and OOP Patterns

* **Access Modifiers:** Explicitly declare class property and method visibility using `public`, `private`, or `protected`.
* **Readonly Properties:** Use the `readonly` modifier for class properties that are initialized in the constructor and should not change.
* **Constructor Parameter Properties:** Utilize constructor parameter shorthand declarations to reduce boilerplate:
  ```typescript
  // Correct
  class OrderService {
      constructor(private readonly repository: OrderRepository) {}
  }
  ```

---

## 4. Generics and Type Guards

* **Keep Generics Clean:** Use descriptive uppercase generic names (e.g. `TResult`, `TEntity`) instead of single letters when the context warrants clarity.
* **Type Guards:** Implement clean type predicate functions (`value is TargetType`) to safely resolve types in runtime:
  ```typescript
  function isApiError(error: unknown): error is ApiError {
      return typeof error === "object" && error !== null && "statusCode" in error;
  }
  ```
