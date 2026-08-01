# React accessibility (web)

React-specific a11y rules. Shared frontend basics live in `frontend-guidelines/` and `html-css-guidelines/` — load those for semantics/CSS; keep this file for component/ARIA/keyboard patterns in React.

---

## MUST

- Expose correct **roles and accessible names** for interactive controls (`button`, `link`, `textbox`, `checkbox`, …). Prefer native elements (`<button>`, `<a href>`, `<label htmlFor>`) over `div` + role when possible.
- Wire labels: every input has a visible `<label>` or `aria-label` / `aria-labelledby`. Icon-only buttons need an accessible name.
- Support **keyboard**: focusable controls, logical tab order, Enter/Space on custom buttons, Escape to dismiss dialogs when that is the product pattern.
- Manage focus when opening/closing modals, drawers, and route transitions that steal context — move focus into the dialog and restore on close when the design system does not already.
- Announce async status with polite live regions (`aria-live`) or existing design-system alert patterns for errors/success the user must notice.
- Preserve semantics in lists, headings, and landmarks; do not skip heading levels arbitrarily for styling.
- Ensure visible **focus** styles are not removed (`outline: none` only with an equally visible replacement).
- Associate error/help text with inputs via `aria-describedby` (or DS equivalent).
- Test critical interactions with RTL `getByRole` (see `testing.md`) so a11y names stay honest.
- Mark decorative icons with `aria-hidden` when a parent already provides the name.

```tsx
<button type="button" aria-label="Close dialog" onClick={onClose}>
  <CloseIcon aria-hidden />
</button>

<label htmlFor="email">Email</label>
<input id="email" aria-describedby="email-error" aria-invalid={!!error} />
{error ? <p id="email-error">{error}</p> : null}
```

---

## MUST NOT

- Use clickable `div`/`span` without role, keyboard handlers, and accessible name.
- Rely on color alone for meaning (errors, selected state) — add text/icon/pattern.
- Trap focus incorrectly (no exit) or leave focus on a removed node after close.
- Hide content from AT with `display: none` / `aria-hidden` while it remains operable.
- Disable lint a11y rules (`jsx-a11y/*`) project-wide to silence real issues.
- Nest interactive controls (button inside button / link inside button).

---

## Prefer when matching repo

| Signal | Prefer |
|--------|--------|
| Design system (MUI, Chakra, BDS, …) | Use DS primitives’ a11y props; do not reimplement dialogs/menus from scratch |
| Blip plugins | Follow `blip-guidelines/design-system.md` + iframe constraints |
| i18n | Accessible names go through the same i18n layer as visible copy |
| Nested interactive controls | Flatten structure; one control per target |
| Router announcements | Use existing live-region / title patterns for SPA navigations |

### Checklist while coding

- [ ] Native element first; ARIA only to fill gaps
- [ ] Label / name present for every control
- [ ] Keyboard path equals mouse path for the changed flow
- [ ] Modal focus move + restore
- [ ] Error text associated via `aria-describedby` or DS equivalent
- [ ] Contrast meets WCAG for text/icons in the changed UI (or DS tokens)

### Common React pitfalls

| Pitfall | Fix |
|---------|-----|
| `div onClick` card | `<button>` or role+keyboard+name |
| Icon button silent | `aria-label` on control |
| Dialog without focus | Focus first control / title; restore on close |
| `placeholder` as only label | Visible `<label>` |

---

## References

- [WAI-ARIA Authoring Practices](https://www.w3.org/WAI/ARIA/apg/)
- [React accessibility](https://react.dev/learn/accessibility)
- [eslint-plugin-jsx-a11y](https://github.com/jsx-eslint/eslint-plugin-jsx-a11y)
- [WCAG 2.2 quickref](https://www.w3.org/WAI/WCAG22/quickref/)
