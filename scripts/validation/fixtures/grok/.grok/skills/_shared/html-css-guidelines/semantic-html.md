# Semantic HTML

Markup standards for accessible, SEO-friendly pages. Visual styling follows `DESIGN-BRIEF.md` when present; this file covers structure only. Pair with `accessibility-basics.md` for focus/contrast and ARIA limits.

---

## MUST

- Declare `<!DOCTYPE html>` and a correct `lang` on `<html>`.
- Use landmarks: `<header>`, `<nav>`, `<main>`, `<aside>`, `<footer>` — **one `<main>`** per page.
- Provide a skip link to `#main` (or equivalent) when layouts are complex / multi-nav.
- Use a single `<h1>` per page for the primary topic; do not skip heading levels (`h1` → `h3`).
- Associate every input with a `<label>` (`for`/`id` or wrapping label).
- Group related fields with `<fieldset>` + `<legend>` when they form a logical set.
- Use **`<a href>` for navigation** and **`<button type="button|submit|reset">` for actions**.
- Meaningful images: descriptive `alt`; decorative images: `alt=""`.
- Use `<ul>` / `<ol>` for lists; `<table>` only for tabular data with `<thead>` / `<th scope>`.
- Prefer native elements over `div`/`span` + ARIA when a native control exists.

```html
<main id="main">
  <h1>Orders</h1>
  <form>
    <label for="q">Search</label>
    <input id="q" name="q" type="search" autocomplete="off" />
    <button type="submit">Search</button>
  </form>
</main>
```

---

## MUST NOT

- Use `<div onclick>` / `<span onclick>` as interactive controls.
- Use `<a>` without `href` as a button; use `<button>`.
- Use tables for layout.
- Skip heading levels to achieve visual size — use CSS for appearance.
- Put multiple `<h1>` elements on one page without a documented design-system exception.
- Rely on ARIA to “fix” non-semantic markup when a native element fits (see `accessibility-basics.md`).

---

## Prefer when matching repo

| Signal | Prefer |
|--------|--------|
| Design system components | Compose primitives that already emit semantic HTML |
| SPA frameworks (React/Vue/Angular) | Same landmark/heading rules inside routed views |
| Markdown-generated pages | Keep heading hierarchy coherent after render |
| SEO meta already present | Unique `<title>` + description per route; OG tags only if already used |
| Icon-only controls | Visible text or `aria-label` per `inclusive-components.md` |

### Links vs buttons

| User intent | Element |
|-------------|---------|
| Go to a URL / route | `<a href>` |
| Submit form | `<button type="submit">` |
| In-page action | `<button type="button">` |

### Document checklist (new pages/views)

- [ ] `lang` set
- [ ] Skip link when multi-nav
- [ ] One `main`, coherent headings
- [ ] Forms fully labelled
- [ ] No layout tables
- [ ] Images have correct `alt` policy

Framework note: the same rules apply inside React/Vue/Angular templates — semantic tags are not optional because JSX/SFC exists.

---

## References

- [HTML — Elements reference (MDN)](https://developer.mozilla.org/en-US/docs/Web/HTML/Element)
- [W3C — HTML landmarks](https://www.w3.org/WAI/ARIA/apg/patterns/landmarks/examples/general-principles.html)
- [MDN — Heading elements](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/Heading_Elements)
- [MDN — `<button>` vs links](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/button)
