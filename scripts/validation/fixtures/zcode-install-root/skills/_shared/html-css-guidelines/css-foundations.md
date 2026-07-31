# CSS foundations

Vanilla CSS patterns for tokens, layout, specificity, and responsive behavior. Token values come from `DESIGN-BRIEF.md` or existing theme files. Modern features (container queries, cascade layers) continue in `modern-css.md`.

---

## MUST

- Define design tokens as **CSS custom properties** at `:root` or a theme scope; reuse project tokens — do not invent a parallel palette when one exists.
- Use **Flexbox** for one-dimensional alignment; **Grid** for two-dimensional page/component shells.
- Prefer `gap` over margin hacks between siblings.
- Set `min-width: 0` (or `min-height: 0`) on flex/grid children that must shrink/truncate.
- Write **mobile-first** base styles; enhance with `@media (min-width: …)`.
- Prefer relative units (`rem`, `em`, `%`, `clamp()`) for typography and spacing.
- Keep specificity low: prefer classes over deep descendant chains; avoid `!important` except third-party overrides.
- Co-locate component styles the way the project already does (CSS modules, BEM files, Tailwind layers, etc.).

```css
:root {
  --color-text: oklch(0.2 0.02 260);
  --color-surface: oklch(0.98 0.01 260);
  --space-md: 1rem;
  --font-body: "Source Sans 3", system-ui, sans-serif;
}

.toolbar {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-md);
  align-items: center;
}

.panel {
  display: grid;
  grid-template-columns: 1fr;
  gap: var(--space-md);
}

@media (min-width: 48rem) {
  .panel {
    grid-template-columns: 16rem 1fr;
  }
}
```

---

## MUST NOT

- Hard-code a second color system when `DESIGN.md` / tokens already exist.
- Use absolute `px` for all type/spacing when the project is rem-based.
- Nest selectors to mimic full DOM depth when a single class suffices.
- Animate layout-thrashing properties by default when `transform`/`opacity` suffice (see also reduced motion).
- Introduce Tailwind / CSS-in-JS / another preprocessor in a small PR when the repo standardizes on plain CSS (or the reverse).

---

## Prefer when matching repo

| Signal | Prefer |
|--------|--------|
| Tailwind / utility CSS | Utility classes + existing config tokens; avoid one-off style tags |
| CSS modules | `*.module.css` beside components |
| SCSS partials | Follow `scss-guidelines.md` |
| Reset already present | Extend; do not add a second normalize |
| Logical properties | `margin-inline`, `padding-block` when neighbors use them |

### Layout cheatsheet

| Problem | Tool |
|---------|------|
| Navbar row | Flex + `gap` |
| Page shell (nav + content) | Grid |
| Truncation in flex child | `min-width: 0` + ellipsis |
| Fluid type | `clamp(min, preferred, max)` |

---

## References

- [MDN — CSS custom properties](https://developer.mozilla.org/en-US/docs/Web/CSS/Using_CSS_custom_properties)
- [MDN — Flexbox](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_flexible_box_layout)
- [MDN — Grid](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_grid_layout)
- [web.dev — Responsive design](https://web.dev/learn/design/)
