# JavaScript Clean Code Guidelines

This document outlines core best practices and clean code guidelines for JavaScript development, adapted from `ryanmcdermott/clean-code-javascript`.

---

## 1. Variables and Naming

* **Use Intention-Revealing Names:** Variable names must be descriptive and pronounceable.
  ```javascript
  // Bad
  const yyyymmdstr = moment().format("YYYY/MM/DD");

  // Good
  const currentDate = moment().format("YYYY/MM/DD");
  ```
* **Use const and let:** Avoid `var`. Use `const` by default for variables that do not change reference; use `let` only when re-assignment is required.
* **Avoid Magic Strings/Numbers:** Extract constants into descriptive objects or exports.

---

## 2. Functions

* **Single Responsibility:** Functions should do one thing and do it well. If a function does multiple actions (e.g., fetches data, formats it, and updates UI), split it.
* **Keep Arguments to a Minimum:** Use destructuring or parameter objects for functions that require more than 2 arguments.
  ```javascript
  // Bad
  function createMenu(title, body, buttonText, cancellable) { ... }

  // Good
  function createMenu({ title, body, buttonText, isCancellable }) { ... }
  ```
* **Default Arguments:** Use ES6 default arguments instead of checking for undefined with ternary operators.
* **Avoid Side Effects:** A function is clean if it does not mutate global states or parameter references. Use array methods that return new instances (like `map`, `filter`, `reduce`) rather than mutative methods (like `push`, `splice`) on parameter arrays.

---

## 3. ES6+ Best Practices

* **Arrow Functions:** Use arrow functions for brief callbacks and methods, especially to preserve the lexical scope of `this`.
* **Destructuring:** Use object and array destructuring to extract properties cleanly.
* **Template Literals:** Use template literals (backticks) instead of string concatenation.
* **Promises and Async/Await:** Always prefer `async/await` over raw Promise `.then()` chains to improve readability and error handling via `try/catch`.

---

## 4. Error Handling

* **Throw Real Errors:** Always throw instances of the `Error` object rather than raw strings.
* **Handle Caught Exceptions:** Do not swallow errors. Log them with trace metadata or pass them up to a central handler.
