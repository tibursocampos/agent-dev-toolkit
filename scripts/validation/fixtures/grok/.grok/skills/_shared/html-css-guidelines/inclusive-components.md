# Inclusive components

Patterns for buttons, links, forms, dialogs, and disclosures that stay usable with keyboard and assistive tech. Builds on `semantic-html.md` and `accessibility-basics.md`.

---

## MUST

- Use **`<a href>`** for navigation and **`<button>`** for actions — never confuse the two.
- Ensure icon-only controls have an accessible name (`aria-label`, visually hidden text, or `aria-labelledby`).
- Keep labels visible when possible; placeholder-only fields are not a label substitute.
- Reflect error state in text + programmatic association (`aria-invalid`, `aria-describedby`), not color alone.
- For dialogs/modals: trap focus while open, restore focus on close, label the dialog (`aria-labelledby` / `aria-label`), and close on Escape when that is the product pattern.
- For disclosures/accordions: `aria-expanded` on the control and controlled panel visibility tied to the same state.
- Ensure custom toggles expose checked/pressed state (`aria-pressed` / native `checkbox` / `switch` pattern per APG).
- Prefer native `<select>`, `<input type="checkbox|radio">` before rebuilding listboxes/radiogroups unless the design system already ships accessible replacements.

```html
<button type="button" aria-expanded="false" aria-controls="filters-panel" id="filters-btn">
  Filters
</button>
<div id="filters-panel" role="region" aria-labelledby="filters-btn" hidden>
  <!-- filters -->
</div>
```

---

## MUST NOT

- Ship clickable cards that are one giant `<div>` without a clear single interactive child or full keyboard support.
- Disable focus styles on custom components.
- Open modals without moving focus into them.
- Use `title` alone as the accessible name for critical controls.
- Recreate tabs/menus without following APG keyboard interaction when inventing from scratch — prefer the design system.

---

## Prefer when matching repo

| Signal | Prefer |
|--------|--------|
| Design system (Blip DS, etc.) | Use library primitives; still verify names/focus |
| Headless UI libraries | Compose visuals on top of accessible behavior |
| Form libraries | Hook into their error-id wiring |
| Toast/live regions | Existing notification component with polite status |

### Component checklist (touched UI)

- [ ] Name, role, value available to AT
- [ ] Keyboard path complete
- [ ] Focus visible
- [ ] Errors announced / associated
- [ ] Motion respects reduced-motion

### Forms and errors

- Visible label + programmatic link for help/error text.
- Do not rely on `placeholder` as the only instruction.
- Disable submit while in-flight if double-submit causes harm; keep the control focusable or explain why not.
- For custom selects/listboxes, prefer design-system widgets that already implement APG keyboard patterns.

Icon-only toolbar buttons need an accessible name even when a tooltip exists — tooltips are not a substitute for the name in all AT/browser combinations.

### Card / list item pattern

Prefer a single primary action inside the card (link or button) rather than making the whole card a `<div @click>`. If the whole row must be clickable, use a stretched link pattern the design system already documents, and keep nested controls carefully labeled.

---

## References

- [APG — Dialog (Modal)](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/)
- [APG — Disclosure](https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/)
- [APG — Button](https://www.w3.org/WAI/ARIA/apg/patterns/button/)
- [MDN — Using ARIA](https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Guides/Techniques)
