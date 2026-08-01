# Modern CSS

Container queries, cascade layers, logical properties, and motion — when the project’s browser targets allow. Foundations remain in `css-foundations.md`.

---

## MUST

- Prefer **container queries** (`@container`) when a component’s layout should respond to **its slot/parent width**, not only the viewport.
- Define `container-type` (and optional `container-name`) on the containment parent before querying.
- Use **`@media (prefers-reduced-motion: reduce)`** for decorative motion; keep essential state changes available without animation.
- Prefer **`transform` / `opacity`** for motion when animating.
- Prefer logical properties (`margin-inline`, `inset-inline`, `padding-block`) when the codebase already targets multi-directional layouts or has adopted them.
- Use `:has()` / `:is()` / `:where()` only when supported by the project’s browserslist / baseline target — match existing usage.
- Prefer `color-mix()` / OKLCH tokens when the theme already uses modern color functions.

```css
.card-grid {
  container-type: inline-size;
  container-name: card-grid;
}

@container card-grid (min-width: 36rem) {
  .card {
    display: grid;
    grid-template-columns: 8rem 1fr;
  }
}

@media (prefers-reduced-motion: reduce) {
  .card {
    transition: none;
  }
}
```

---

## MUST NOT

- Replace all viewport media queries with container queries blindly — use CQ when layout depends on the component slot.
- Animate `width`/`top`/`left` for continuous motion when transforms work.
- Ignore reduced-motion preferences for parallax, large transitions, or autoplay-like UI.
- Ship CSS that requires bleeding-edge features unsupported by the repo’s documented browser list without fallbacks.
- Nest `@media` / `@container` excessively when a flatter structure reads clearer.

---

## Prefer when matching repo

| Signal | Prefer |
|--------|--------|
| Cascade layers (`@layer`) | Extend existing layer order (reset → tokens → components → utilities) |
| PostCSS / Lightning CSS | Use the pipeline already configured |
| View transitions API | Only when already adopted |
| Subgrid | When parents already use grid + subgrid patterns |
| `clamp` + CQ together | Fluid type + component-level layout shifts |

### Viewport vs container

| Question | Use |
|----------|-----|
| Does the whole page chrome change? | `@media` |
| Does this card/list change inside a sidebar vs main? | `@container` |
| Is motion decorative? | Gate with `prefers-reduced-motion` |

### Progressive enhancement notes

- Provide a usable layout without container query support when the project still supports older browsers — typically the mobile-first single-column base.
- Prefer feature queries (`@supports`) only when neighbors already use them for the same feature.
- Keep critical text readable if custom fonts fail to load (system fallbacks in the stack).

---

## References

- [MDN — Container queries](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_containment/Container_queries)
- [MDN — `@media` (prefers-reduced-motion)](https://developer.mozilla.org/en-US/docs/Web/CSS/@media/prefers-reduced-motion)
- [MDN — Cascade layers](https://developer.mozilla.org/en-US/docs/Web/CSS/@layer)
- [web.dev — Container queries](https://web.dev/blog/css-container-queries)
