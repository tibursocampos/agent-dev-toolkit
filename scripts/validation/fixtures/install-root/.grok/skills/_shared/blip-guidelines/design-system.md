# Blip Design System (BDS) Guidelines

Usage of Blip Design System in React plugins (Lite and Full profiles).

## Initialization

BDS web components must be registered before the React tree renders:

```javascript
// src/lib/setup/blip-ds.js
import { applyPolyfills, defineCustomElements } from 'blip-ds/loader';

void applyPolyfills().then(() => defineCustomElements(window));
```

Import this module first in `src/index.js`.

## Typography

Official font: **Nunito Sans** via `@fontsource/nunito-sans`. Load in `src/lib/setup/fonts.js` and set as Tailwind default.

## Tailwind + BDS tokens

Use Tailwind with the `tailwind-blip-ds` plugin - avoid raw CSS/SCSS for layout and colors.

```javascript
// tailwind.config.js
module.exports = {
  content: ['./src/**/*.{js,jsx,ts,tsx}'],
  plugins: [require('tailwind-blip-ds')],
};
```

Use design tokens from `tailwind-blip-ds` for colors, spacing, and typography.

## Web components (`<bds-*>`)

**Lite profile** and simple UIs: use BDS web components directly in JSX.

```jsx
<bds-button variant="primary" onClick={handleSave}>
  {t('save')}
</bds-button>
<bds-loading-page />
```

Notes for React:

- Pass data via HTML attributes or properties
- Custom element events may need lowercase handlers or refs for complex objects
- Test with Cypress, not Jest DOM

Common components: `bds-button`, `bds-input`, `bds-select`, `bds-loading-page`, `bds-toast` (prefer iframe toast for portal-native notifications - see `blip-iframe-messages.md`).

## React wrappers (`blip-ds-react`)

**Full profile** and complex forms: use `blip-ds-react` wrappers where the project already depends on them.

```jsx
import { BdsButton, BdsInput } from 'blip-ds-react';

<BdsButton variant="primary" onClick={handleSave}>
  {t('save')}
</BdsButton>
```

Prefer consistency within a project - do not mix web components and React wrappers for the same control type in one screen without reason.

## Layout patterns

- Use Tailwind utility classes aligned with BDS spacing scale
- Page shell: loading state via `<bds-loading-page />` or route-level suspense
- Tables and grids: follow existing project patterns with BDS tokens; prefer dedicated table components over ad-hoc markup when the repo already has them

## Do not

- Import generic UI libraries (Material, Bootstrap) alongside BDS
- Hardcode hex colors when a BDS/Tailwind token exists
- Use Inter or other non-Blip fonts as primary typography
- Skip BDS initialization in the entry point

## Impeccable handoff

When `docs/DESIGN-BRIEF.md` exists, map visual decisions to BDS components and tokens in section 9 (stack notes). Do not introduce non-BDS patterns during implementation.
