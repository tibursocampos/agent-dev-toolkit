# DOM patterns

For vanilla HTML/CSS/JS work and progressive enhancement. Pair with `html-css-guidelines` (semantic HTML / a11y) and `frontend-guidelines` hub docs — do not duplicate full a11y essays here.

---

## MUST

- Prefer `document.querySelector` / `querySelectorAll` with specific selectors; cache references reused across handlers.
- Use `classList.add` / `remove` / `toggle` instead of string-concatenating `className`.
- Use `textContent` for untrusted or plain text; use `innerHTML` only with trusted or sanitized HTML.
- Register listeners deliberately; remove them on teardown (SPA route change, component destroy, dialog close).
- Keep keyboard support: `keydown` shortcuts respect focus context; interactive elements remain reachable via Tab.
- Sync ARIA state with UI (`aria-expanded`, `aria-hidden`, `aria-selected`) when toggling widgets.
- Separate DOM binding from business logic (small modules/functions); avoid accidental globals.
- Keep identifiers and comments in **English**.

---

## MUST NOT

- Inject unsanitized user HTML via `innerHTML` / `document.write`.
- Query the DOM inside hot animation loops without caching or batching.
- Trap focus incorrectly or forget to restore focus when closing modal dialogs.
- Rely on JS for critical content when progressive enhancement is feasible and the project expects it.
- Attach dozens of duplicate listeners on dynamic lists — prefer delegation from a stable parent.
- Use `positive: false` passive mistakes: mark scroll/touch listeners `{ passive: true }` when not calling `preventDefault`.

---

## Prefer when matching repo

### Events and performance

| Topic | Prefer |
|-------|--------|
| Dynamic lists | Event delegation on parent |
| Scroll / touch | `{ passive: true }` when possible |
| Visual updates | `requestAnimationFrame` for scroll/resize-tied work |
| Resize / search | Debounce / throttle matching existing utils |
| Reads/writes | Batch DOM reads then writes to avoid layout thrashing |

### Progressive enhancement

- Core content and forms work without JavaScript when feasible.
- Enhance with loading states, client validation, and async submit.
- Feature-detect before using newer APIs; provide fallbacks when broad support is required.

### Accessibility in scripts

- Move focus into dialogs on open; trap focus while open; restore on close.
- Announce dynamic updates with `aria-live` when content changes without navigation.
- Ensure custom controls expose correct `role` and name (see html-css a11y docs).

### Module organization

```javascript
// Prefer — bind UI, call pure logic
export function bindOrderForm(form, { onSubmit }) {
  form.addEventListener('submit', (event) => {
    event.preventDefault();
    onSubmit(readOrderForm(form));
  });
}
```

- ES modules or the project’s bundler conventions; IIFE only when the repo still uses that pattern.
- Pair automated checks with behavior-focused tests when a test runner exists (Testing Library / Playwright — match repo).

### Checklist (DOM change)

- [ ] No unsanitized `innerHTML` of user data
- [ ] Listeners removed or delegated correctly
- [ ] Keyboard and focus paths work for new widgets
- [ ] ARIA attributes stay in sync with visible state
- [ ] No layout thrashing in scroll/resize handlers
- [ ] Core form/content still usable if JS fails (when progressive enhancement applies)

### Safe text vs HTML

```javascript
// Prefer for untrusted data
el.textContent = userProvidedName;

// Only with sanitizer / trusted CMS HTML the project already uses
el.innerHTML = sanitizer.sanitize(trustedHtml);
```

---

## References

- [MDN — Document.querySelector](https://developer.mozilla.org/en-US/docs/Web/API/Document/querySelector)
- [MDN — Event best practices](https://developer.mozilla.org/en-US/docs/Learn/JavaScript/Building_blocks/Events)
- [MDN — Using ARIA](https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA)
- [WAI-ARIA Authoring Practices](https://www.w3.org/WAI/ARIA/apg/)
