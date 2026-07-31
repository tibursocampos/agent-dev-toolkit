# Google TypeScript style conventions

Formatting and naming adapted from Google TypeScript Style / gts themes. **Defer to the repo’s Prettier/ESLint/gts config** when present. Pair with `typescript-strict.md`.

---

## MUST

- Use **PascalCase** for classes, interfaces, types, and enums; **camelCase** for variables, parameters, functions, and methods; **UPPER_SNAKE_CASE** for true constants.
- Prefer **kebab-case** file names when the project already uses them (`order-processor.ts`); otherwise match neighbor files.
- Prefer explicit named imports; avoid `import *` unless the project pattern requires it.
- Prefer named exports when neighbors do (searchable, explicit symbols).
- Keep statements consistent with the project semicolon/quote rules (gts defaults: semicolons on; single quotes unless template literals).
- Keep identifiers and comments in **English**.

---

## MUST NOT

- Fight Prettier/ESLint/gts on indentation, quotes, or line width — run the project formatter.
- Invent a new naming scheme beside an established one in the same folder.
- Use default exports in packages that standardize on named exports (or the reverse) without matching neighbors.
- Use deep relative imports (`../../../../`) when path aliases are configured in `tsconfig`.
- Introduce spaces/tabs mix; follow the project indent (gts often **2 spaces** when no Prettier override).

---

## Prefer when matching repo

| Topic | gts-like default | Override when |
|-------|------------------|---------------|
| Indent | 2 spaces | Prettier `tabWidth` says otherwise |
| Line length | ~80 | Prettier `printWidth` (often 100) |
| Quotes | Single | Double if Prettier enforces |
| Semicolons | Required | `semi: false` in Prettier |
| Braces | Egyptian / OTBS same-line `{` | Existing formatter |

### Naming quick reference

| Kind | Form |
|------|------|
| Class / interface / type / enum | `UserSession` |
| Variable / function / method | `fetchData`, `userId` |
| Constant | `MAX_RETRIES` |
| File | `order-processor.ts` (if repo kebab-case) |

### Imports

```typescript
import { useState, useEffect } from 'react';
```

- Prefer `@/` (or project alias) for deep paths when configured.
- Keep import groups consistent with ESLint import-order rules already enabled.

### Control flow braces

```typescript
if (condition) {
  doSomething();
} else {
  doOtherThing();
}
```

---

## References

- [Google TypeScript Style Guide](https://google.github.io/styleguide/tsguide.html)
- [gts — Google TypeScript Style](https://github.com/google/gts)
- [TypeScript — Modules](https://www.typescriptlang.org/docs/handbook/modules.html)
