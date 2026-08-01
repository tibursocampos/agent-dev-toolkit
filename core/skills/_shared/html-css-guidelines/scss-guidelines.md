# SCSS guidelines

Use when the project already has `.scss` / `.sass` files. Match existing partial structure and naming. Prefer CSS custom properties for runtime theming when the project supports dark mode / tokens at runtime.

---

## MUST

- Keep nesting **≤ 3 levels** (prefer 1–2); do not nest selectors merely to mirror DOM depth when a BEM/class suffices.
- Put shared tokens in a single settings partial (or CSS variables partial); do not duplicate hex/rgb values across files.
- Prefer **mixins** for small repeated patterns (visually-hidden, focus ring) — document parameters; keep mixin bodies greppable.
- Follow the project’s partial naming (`_variables.scss`, `_mixins.scss`, component files).
- When the project uses **BEM**, stick to Block / `__` Element / `--` Modifier consistently.
- When the project uses **ITCSS** (or similar layers), place new code in the correct layer — do not drop component rules into settings/tools.

```scss
.card {
  padding: var(--space-md);

  &__title {
    font-size: 1.125rem;
  }

  &--featured {
    border-color: var(--color-accent);
  }
}

@mixin focus-ring {
  &:focus-visible {
    outline: 2px solid var(--color-focus);
    outline-offset: 2px;
  }
}
```

---

## MUST NOT

- Nest `@media` deeply inside selectors without strong reason — prefer flat queries or modern CSS when neighbors do.
- Build deep chains (`.page .sidebar .nav .item a`).
- Hide large CSS blobs inside opaque mixins that are hard to search.
- Introduce Sass modules/`@use` migration mid-feature if the repo still uses `@import` globally (match until a dedicated migration).
- Add SCSS to a CSS-only package without user ask.

---

## Prefer when matching repo

| Signal | Prefer |
|--------|--------|
| Dart Sass `@use` / `@forward` | Module system already in use |
| Legacy `@import` | Keep consistency; avoid mixed module styles in one PR |
| CSS variables for themes | `$color-primary: var(--color-primary);` bridge |
| Angular `styleUrls` SCSS | Component-scoped files + shared partials via `angular.json` `includePaths` |
| Vite `additionalData` | Shared variables injected already — reuse |

### ITCSS order (when used)

1. Settings (variables)
2. Tools (mixins, functions)
3. Generic (reset)
4. Elements (bare HTML)
5. Objects (layout)
6. Components
7. Utilities

### Nesting example (allowed vs too deep)

```scss
// Prefer
.nav {
  display: flex;
  gap: var(--space-sm);

  &__link {
    @include focus-ring;
  }
}

// Avoid — DOM-mimic depth
.page {
  .sidebar {
    .nav {
      .item {
        a { color: red; }
      }
    }
  }
}
```

---

## References

- [Sass — Style rules / nesting](https://sass-lang.com/documentation/style-rules/)
- [Sass — `@use`](https://sass-lang.com/documentation/at-rules/use/)
- [Get BEM](https://getbem.com/)
- [ITCSS overview](https://www.xfive.co/blog/itcss-scalable-maintainable-css-architecture/)
