# HTML/CSS delivery checklist

Use before opening a pull request for markup/CSS work (including when a framework skill delegates styling here).

---

## Preparation

- [ ] `AGENTS.md` / README / DESIGN-BRIEF reviewed when UI is visual
- [ ] Acceptance criteria clear (structure vs visual tokens)
- [ ] Browser / CSS toolchain confirmed (plain CSS, SCSS, Tailwind, modules)

---

## Branching

- [ ] Working branch: `feature/<slug>` or `feat/<id>-<slug>`
- [ ] Based on the correct default branch

---

## Markup

- [ ] Landmarks + one `<main>`; sensible heading order
- [ ] Labels on inputs; fieldsets when needed
- [ ] `<a>` for navigation; `<button>` for actions
- [ ] Meaningful / decorative `alt` handled correctly
- [ ] Semantics before ARIA

---

## Accessibility

- [ ] `:focus-visible` retained or replaced intentionally
- [ ] Contrast checked for touched text/UI
- [ ] Keyboard path works for new controls
- [ ] `prefers-reduced-motion` respected for new animation
- [ ] Dialogs/disclosures follow inclusive patterns when added

---

## CSS

- [ ] Tokens reused (no parallel palette)
- [ ] Flex/Grid + `gap` as appropriate; `min-width: 0` where truncating
- [ ] Mobile-first media queries
- [ ] Container queries when layout depends on slot width
- [ ] SCSS nesting ≤ 3 / BEM-ITCSS matched when applicable
- [ ] No unnecessary `!important`

---

## Before PR

- [ ] Diff limited to stated acceptance (YAGNI)
- [ ] No new CSS framework without ask
- [ ] Conventional commit message ready (via `/commit` when requested)
- [ ] Guideline paths touched: `semantic-html`, `accessibility-basics`, `css-foundations`, `modern-css`, `scss-guidelines`, `inclusive-components` as applicable

### Quick verify

- Keyboard-only pass on touched controls
- Contrast spot-check on new text/surfaces (both themes if dark mode exists)
- Resize / container width check when layout is slot-dependent
- Reduced-motion: animations do not block comprehension

### Commands (when applicable)

```bash
npm run lint
npm run build
```

Use the project’s stylelint / prettier / axe scripts when present. Do not add new linters in a small markup PR.

---

## References

- [WCAG 2.2 Quick Reference](https://www.w3.org/WAI/WCAG22/quickref/)
- [MDN — HTML elements](https://developer.mozilla.org/en-US/docs/Web/HTML/Element)
- [MDN — Container queries](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_containment/Container_queries)
- [WAI-ARIA Authoring Practices](https://www.w3.org/WAI/ARIA/apg/)
