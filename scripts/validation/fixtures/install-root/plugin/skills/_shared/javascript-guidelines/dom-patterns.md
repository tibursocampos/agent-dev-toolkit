# DOM Patterns

For vanilla HTML/CSS/JS work and progressive enhancement. Pair with `html-css-guidelines/semantic-html.md`.

## DOM APIs

- Prefer `document.querySelector` / `querySelectorAll` with specific selectors.
- Cache references when reused; avoid querying inside hot loops.
- Use `classList.add/remove/toggle` instead of string concatenation on `className`.
- `textContent` for text; `innerHTML` only with trusted or sanitized content.

## Events

- Register listeners with `{ passive: true }` for scroll/touch when not calling `preventDefault`.
- Delegate events from stable parents when lists are dynamic.
- Remove listeners on teardown (SPA route changes, component destroy).
- Use `keydown` for keyboard shortcuts; respect focus context.

## Progressive enhancement

- Core content and forms work without JavaScript when feasible.
- Enhance with JS: loading states, client validation, async submit.
- Feature-detect before using newer APIs; provide fallbacks when the project requires broad support.

## Accessibility in scripts

- Toggle `aria-expanded`, `aria-hidden`, `aria-selected` with visible state changes.
- Move focus to dialogs on open; trap focus; restore on close.
- Announce dynamic updates via `aria-live` regions when content changes without navigation.

## Module organization

- Separate DOM binding from business logic (small modules or functions).
- Avoid global variables; use IIFE or ES modules per project setup.

## Performance

- Batch DOM reads/writes; avoid layout thrashing.
- Use `requestAnimationFrame` for visual updates tied to scroll or resize.
- Debounce resize/search handlers when appropriate.
