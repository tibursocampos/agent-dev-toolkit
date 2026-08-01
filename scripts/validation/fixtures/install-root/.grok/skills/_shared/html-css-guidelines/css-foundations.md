# CSS Foundations

Vanilla CSS patterns for layout, tokens, and responsive behavior. Token values come from `DESIGN-BRIEF.md` or existing project theme files.

## Custom properties (tokens)

Define design tokens at `:root` or a theme scope:

```css
:root {
  --color-text: oklch(0.2 0.02 260);
  --color-surface: oklch(0.98 0.01 260);
  --space-md: 1rem;
  --font-body: system-ui, sans-serif;
}
```

Reuse project tokens; do not invent a parallel palette when `DESIGN.md` or CSS variables already exist.

## Layout

- **Flexbox**: one-dimensional alignment (toolbars, card rows, form rows).
- **Grid**: two-dimensional layouts (page shells, card grids, dashboards).
- Prefer `gap` over margin hacks between siblings.
- Use `min-width: 0` on flex/grid children that must shrink and truncate.

## Responsive design

- Mobile-first: base styles for small viewports; `@media (min-width: …)` for larger.
- Use relative units (`rem`, `em`, `%`, `clamp()`) for typography and spacing.
- Test at common breakpoints; avoid horizontal overflow on narrow screens.

## Contrast and focus

- Body text: minimum 4.5:1 contrast against background.
- Large text (≥18pt or 14pt bold): minimum 3:1.
- Visible `:focus-visible` styles on all interactive elements.
- Respect `prefers-reduced-motion: reduce` for animations.

## Specificity and maintainability

- Prefer class selectors over deep nesting.
- Avoid `!important` except overrides for third-party widgets.
- Co-locate component styles with components when the project uses that pattern.

## Performance

- Minimize unused CSS in critical path.
- Prefer `transform` and `opacity` for animations (compositor-friendly).
- Load fonts the way the project already does; do not add web font stacks without design approval.
