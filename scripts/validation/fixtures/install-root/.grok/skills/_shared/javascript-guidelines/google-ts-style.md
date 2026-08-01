# Google TypeScript Style Conventions

These style conventions represent the formatting and naming rules adapted from Google's official TypeScript Style Guide (`google/gts`).

---

## 1. Naming Conventions

* **Identifiers:**
  * **Classes, Interfaces, Types, Enums:** PascalCase (e.g. `UserSession`).
  * **Variables, Parameters, Functions, Methods:** camelCase (e.g. `fetchData`, `userId`).
  * **Constants:** UPPER_SNAKE_CASE (e.g. `MAX_RETRIES`).
  * **Files/Modules:** lowercase with hyphens (kebab-case) (e.g. `order-processor.ts`).

---

## 2. Formatting & Syntax

* **Indentation:** Use 2 spaces for indentation. Do not use tabs.
* **Line Length Limit:** Limit lines to **80 characters**.
* **Semicolons:** Semicolons are required at the end of every statement.
* **Strings:** Use single quotes (`'`) for string literals by default, unless using template literals for interpolation.
* **Braces:** Use the "Egyptian" style (OTBS - One True Brace Style), where the opening brace is on the same line as the statement:
  ```typescript
  if (condition) {
    doSomething();
  } else {
    doOtherThing();
  }
  ```

---

## 3. Imports and Exports

* **Explicit Imports:** Do not use wildcard imports. Specify only the members you require:
  ```typescript
  import { useState, useEffect } from 'react';
  ```
* **Relative Paths:** Use absolute paths with aliases (e.g. `@/components/`) configured in `tsconfig.json` for deep imports, avoiding long relative traversal (`../../../../utils`).
* **Clean Exports:** Prefer named exports (`export const MyComponent = ...`) over default exports (`export default`) to make imports searchable and explicitly typed.
