# React Native structure and navigation

Primary layout and navigation rules for **React Native** / **Expo**. Prefer this pack over web `react-guidelines/` for navigation, StyleSheet, and platform splits. Shared Hooks/composition habits may still come from `react-guidelines/` when useful.

---

## MUST

- Confirm **Expo vs bare RN** from `package.json` / `app.json` / `app.config.*` before inventing folders.
- Keep **screens thin**: UI + wiring; business rules in hooks/services matching the existing project layout.
- Use **one navigation stack**: either **Expo Router** (file routes under `app/`) **or** **React Navigation** (`@react-navigation/*`) as already adopted — do not add a second root navigator.
- Colocate routes with the existing `app/` (Expo Router) or `navigation/` / stack files (RN Navigation); extend typed params the way the repo already does.
- Keep auth gates, deep links, and modal stacks inside the existing navigator pattern (nested stacks/tabs as already structured).
- Route mobile work through `/react-native-developer`. Do **not** treat Blip / web plugin guidelines as mobile defaults.
- Identifiers, comments, and logs in **English**.

| Signal | Typical markers |
|--------|-----------------|
| Expo | deps `expo`; `app.json` / `app.config.*`; Expo Router under `app/` |
| React Native CLI | deps `react-native`; `android/` / `ios/` (or CNG with Expo) |
| Navigation | Expo Router file routes, **or** `@react-navigation/*` stacks/tabs |

---

## MUST NOT

- Mount Expo Router **and** a parallel React Navigation root for the same app surface in one change.
- Import web DOM APIs, `react-router` DOM routers, or CSS files assuming a browser.
- Copy `react-guidelines/` performance/`'use client'` rules as if they were RN defaults.
- Create parallel screen trees (`screens/` vs `app/`) when one convention already owns routing.
- Pass untyped or loosely typed route params when the project already uses typed `ParamList` / Expo typed routes.
- Navigate via imperative hacks that bypass the configured linking prefixes.

---

## Prefer when matching repo

| Signal | Prefer |
|--------|--------|
| Expo Router present | File-based routes, layouts, `Link` / `router` from `expo-router` |
| React Navigation only | Existing stack/tab/drawer; typed `ParamList` |
| Feature folders | `features/<name>/` with screens importing into navigator/routes |
| Shared UI package | Reuse design primitives; do not fork a second button system |
| Auth redirect | Existing protected layout / listener — extend, do not replace |

### Layout habits

| Concern | Prefer |
|---------|--------|
| Screens | Thin screen components; rules in hooks/services |
| Navigation | One stack family only |
| Lists | FlatList/FlashList — see `lists-and-performance.md` |
| Config | `expo-config-and-env.md` — no secrets |

### Implementation checklist (while coding)

- Confirm Expo vs bare RN from config before new folders
- Keep screens thin; colocate navigation with existing `app/` or `navigation/`
- Reuse shared React patterns from `react-guidelines/` only for hooks/composition — not for DOM or web CSS
- Deep links / auth gates follow the existing navigator pattern
- Typed params updated when adding a screen

### Anti-patterns

```text
❌ app/ (Expo Router) + App.tsx creating NavigationContainer root for same flows
❌ import { BrowserRouter } from 'react-router-dom'
❌ New Screens/ folder beside app/ that never registers routes
```

---

## References

- [Expo Router](https://docs.expo.dev/router/introduction/)
- [React Navigation](https://reactnavigation.org/docs/getting-started/)
- [Expo project structure](https://docs.expo.dev/develop/project-structure/)
- [React Native environment setup](https://reactnative.dev/docs/environment-setup)
