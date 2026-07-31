# Vue accessibility

Vue-specific a11y habits. Shared semantics/CSS basics live in `html-css-guidelines/` and hub `frontend-guidelines/` — load those for landmarks/contrast; keep this file for component/ARIA/keyboard patterns in Vue.

---

## MUST

- Prefer **semantic HTML** inside SFCs (`button`, `a`, `label`, headings) before ARIA role patches.
- Associate every form control with a visible `<label>` (or `aria-label` when the design truly has no visible label — rare).
- Ensure interactive custom components are keyboard reachable (`tabindex` only when necessary; prefer native controls).
- Manage focus when opening/closing dialogs/menus (move focus in, restore on close) using the project’s focus-trap pattern or VueUse helpers if already depended.
- Wire `aria-*` state to reactive data (`:aria-expanded="open"`, `:aria-busy="pending"`) — do not hardcode stale ARIA.
- Announce async status changes via polite live regions when the product requires it and neighbors already do.
- Respect `prefers-reduced-motion` for Vue transitions (`<Transition>` / CSS) — provide a reduced variant or skip animation.

```vue
<button type="button" :aria-expanded="open" :aria-controls="panelId" @click="open = !open">
  Filters
</button>
<div :id="panelId" v-show="open" role="region" :aria-labelledby="/* control id */">
  <!-- panel -->
</div>
```

---

## MUST NOT

- Use `<div @click>` as a button without keyboard handlers and role — prefer `<button type="button">`.
- Put `v-if` on focused elements without a focus fallback (focus loss traps).
- Override focus outlines globally without `:focus-visible` replacements.
- Add redundant ARIA that conflicts with native semantics (`role="button"` on `<button>`).
- Duplicate long WCAG essays from html-css packs into every SFC.

---

## Prefer when matching repo

| Signal | Prefer |
|--------|--------|
| Headless UI / Reka / Radix Vue | Use library a11y primitives already in the design system |
| eslint-plugin-vuejs-accessibility | Fix violations rather than disabling |
| i18n | Locale strings for `aria-label` via existing i18n API |
| Icon-only buttons | Visible text or `aria-label` + tooltip pattern already used |

### Keyboard checklist (touched UI)

- [ ] Tab order is logical
- [ ] Enter/Space activate buttons
- [ ] Escape closes overlays when that is the product pattern
- [ ] Focus visible on custom controls

### Vue-specific pitfalls

- Do not bind `v-html` to untrusted content (XSS). Sanitize or avoid.
- `aria-*` bindings must track reactive state — a one-time string attribute goes stale after toggles.
- When using `<Teleport>` for modals, still manage focus and `aria-modal` per the design system.
- Prefer native elements inside SFCs even when wrapping with styled components.

Cross-load `html-css-guidelines/semantic-html.md` and `accessibility-basics.md` for landmarks, contrast, and reduced motion — do not restate those paragraphs here.

### Testing note

When adding interactive SFCs, cover the accessible name / expanded state in component tests where feasible (role queries). Prefer Testing Library role selectors when the project already uses them.

---

## References

- [Vue — Accessibility](https://vuejs.org/guide/best-practices/accessibility.html)
- [WAI-ARIA Authoring Practices](https://www.w3.org/WAI/ARIA/apg/)
- [MDN — ARIA](https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA)
- [eslint-plugin-vuejs-accessibility](https://github.com/vue-a11y/eslint-plugin-vuejs-accessibility)
