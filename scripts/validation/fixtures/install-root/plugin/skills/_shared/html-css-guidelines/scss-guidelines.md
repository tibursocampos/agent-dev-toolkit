# SCSS Guidelines

Use when the project already has `.scss` / `.sass` files. Match existing partial structure and naming.

## When to use SCSS features

- **Variables / maps**: theme tokens shared across partials.
- **Mixins**: repeated patterns (visually hidden, focus ring) - keep mixins few and documented.
- **Partials**: `_variables.scss`, `_mixins.scss`, component-scoped files.

## Nesting limits

- Maximum **3 levels** of nesting; prefer 1-2.
- Do not nest selectors to mimic DOM depth when a BEM class suffices.
- Never nest `@media` more than one level inside a selector block without strong reason.

## BEM (when project uses it)

```scss
.card { }
.card__title { }
.card--featured { }
```

- Block: standalone component.
- Element: `__` - part of block.
- Modifier: `--` - variant or state.

## ITCSS / layer order (when project uses it)

1. Settings (variables)
2. Tools (mixins, functions)
3. Generic (reset, normalize)
4. Elements (bare HTML)
5. Objects (layout patterns)
6. Components
7. Utilities

## Tokens via variables

Map `DESIGN-BRIEF.md` tokens to SCSS variables or CSS custom properties at compile time:

```scss
$color-primary: var(--color-primary);
```

Prefer CSS custom properties for runtime theming (dark mode) when the project supports it.

## Anti-patterns

- Deep selector chains (`.page .sidebar .nav .item a`).
- Mixins that hide large CSS blocks (hard to grep).
- Duplicating token values in multiple partials - single source of truth.
