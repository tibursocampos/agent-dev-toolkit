# JavaScript clean code

Core clean-code practices for JavaScript, adapted from clean-code-javascript themes. For TypeScript projects prefer `clean-code-ts.md` + `typescript-strict.md` on `.ts` files.

---

## MUST

- Use intention-revealing, pronounceable names; extract magic strings/numbers into named constants.
- Prefer `const` by default; use `let` only when reassignment is required — never `var` in new code.
- Keep functions single-purpose and small; split fetch/format/update pipelines into steps.
- Limit positional arity; use destructured parameter objects when neighbors do (or when args exceed ~2–3).
- Prefer `async/await` over long `.then()` chains; handle failures with `try/catch` or central handlers.
- Throw real `Error` instances (or project error types), not raw strings.
- Keep identifiers and comments in **English**.

---

## MUST NOT

- Swallow exceptions in empty `catch` blocks — log with context or propagate to a central handler.
- Mutate caller-owned arrays/objects when a non-mutating approach (`map`/`filter`/`toSorted`) matches project style.
- Use `==` loose equality in new code; prefer `===` / `!==`.
- Rely on `var` hoisting or accidental globals.
- Hide side effects in getters or surprisingly named helpers (`getX` that writes to DB).
- Leave `console.log` debug noise in production paths when a logger exists.

---

## Prefer when matching repo

### Naming and constants

```javascript
// Bad
const yyyymmdstr = moment().format('YYYY/MM/DD');

// Good
const currentDate = moment().format('YYYY/MM/DD');
```

### Functions

```javascript
// Prefer parameter object when arity grows
function createMenu({ title, body, buttonText, isCancellable }) {
  /* ... */
}
```

- Default parameters instead of `x = x || default` / ternary undefined checks.
- Arrow functions for short callbacks and lexical `this`; match class/method style already used.
- Destructuring and template literals over verbose property access / concatenation.

### ES modules

| Topic | Prefer |
|-------|--------|
| Exports | Named exports when the project prefers them (searchable imports) |
| Side effects | Isolate in entry files |
| Async flow | `async/await`; Promise combinators when already idiomatic |
| Collections | Immutable-friendly methods when ES version supports them |

### Error handling

```javascript
try {
  await service.run(input);
} catch (err) {
  logger.error({ err }, 'run failed');
  throw err; // or map to domain error
}
```

- Pair with `node-structure-errors.md` for HTTP APIs.
- Pair with `dom-patterns.md` for browser event/error UI feedback.

---

## References

- [ryanmcdermott/clean-code-javascript](https://github.com/ryanmcdermott/clean-code-javascript)
- [MDN — Working with objects](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Working_with_objects)
- [MDN — Promise](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise)
- [Node.js Best Practices — Code style](https://github.com/goldbergyoni/nodebestpractices#3-code-style-practices)
