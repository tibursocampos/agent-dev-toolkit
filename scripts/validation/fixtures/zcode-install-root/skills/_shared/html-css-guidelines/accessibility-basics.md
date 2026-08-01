# Accessibility basics (HTML/CSS)

Foundational a11y for markup and CSS. **Semantics before ARIA.** Component patterns continue in `inclusive-components.md`. Framework-specific notes live in stack packs (React/Vue/Angular).

---

## MUST

- Prefer correct HTML semantics; add ARIA only when native semantics are insufficient.
- Ensure **keyboard** access for all interactive controls (Tab, Enter/Space where appropriate, Escape for dismissible overlays when that is the product pattern).
- Provide a visible **`:focus-visible`** style on interactive elements; do not remove outlines without a replacement.
- Meet contrast targets: body text **≥ 4.5:1**; large text (≥18pt / 14pt bold) **≥ 3:1**; UI components/graphics **≥ 3:1** against adjacent colors.
- Keep hit targets reasonably large; do not rely on color alone to convey state.
- Respect **`prefers-reduced-motion: reduce`** — reduce or disable non-essential animation.
- Link errors and hints to controls with `aria-describedby` / `aria-errormessage` when used; keep messages in the accessibility tree.
- Use `aria-live` politely for important async status when neighbors already do.

```css
:focus-visible {
  outline: 2px solid var(--color-focus);
  outline-offset: 2px;
}

@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

---

## MUST NOT

- Use ARIA to paper over `<div>` soup when a button/link/input exists.
- Remove focus indicators globally (`outline: none` on `*`).
- Ship text/icons below contrast minimums against the actual background (including images/gradients).
- Trap keyboard focus unintentionally without an escape path.
- Animate critical content in ways that ignore `prefers-reduced-motion`.
- Duplicate long WCAG essays into every feature PR description — follow this pack + APG patterns.

---

## Prefer when matching repo

| Signal | Prefer |
|--------|--------|
| Design tokens for focus/contrast | Reuse `--color-focus`, surface tokens from theme |
| axe / Lighthouse CI | Fix reported issues on touched pages |
| Overlay libraries | Use existing focus-trap utilities |
| Dark mode | Re-check contrast for both themes |

### ARIA quick rules

| Do | Don't |
|----|-------|
| `aria-expanded` on disclosure buttons | `role="button"` on `<button>` |
| `aria-labelledby` pointing at visible title | Conflicting labels (visible vs aria) |
| `alt=""` on decorative images | Empty `alt` on informative images |

### Focus and motion minimum

- Interactive elements must show `:focus-visible` (or an equivalent design-system focus ring).
- Do not animate opacity/transform of essential content without a reduced-motion path.
- Prefer `scroll-behavior: smooth` only when gated or unnecessary under reduced motion.
- Test keyboard-only once on every new dialog, menu, or custom control before PR.

Pair with `inclusive-components.md` for dialogs, disclosures, and icon-only buttons.

---

## References

- [WCAG 2.2 Quick Reference](https://www.w3.org/WAI/WCAG22/quickref/)
- [WAI-ARIA Authoring Practices](https://www.w3.org/WAI/ARIA/apg/)
- [MDN — `:focus-visible`](https://developer.mozilla.org/en-US/docs/Web/CSS/:focus-visible)
- [MDN — `prefers-reduced-motion`](https://developer.mozilla.org/en-US/docs/Web/CSS/@media/prefers-reduced-motion)
