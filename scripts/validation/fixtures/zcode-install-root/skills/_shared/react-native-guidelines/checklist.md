# React Native / Expo delivery checklist

Use before opening a pull request. Prefer **Jest** + **React Native Testing Library** on greenfield; otherwise match the project's test stack. For web React, use `react-guidelines/checklist.md`.

When ARCH or CONTINUITY needs frontend folder layout, load `../frontend-guidelines/frontend-architecture.md` (shared hub; Expo Router stays a thin `app/` shell over features) — do not invent a full Clean Architecture tree inside this RN pack.

---

## Preparation

- [ ] `AGENTS.md` / README and relevant skills reviewed
- [ ] PLAN step (if applicable) understood; acceptance criteria clear
- [ ] Expo vs bare RN confirmed from project config
- [ ] Loaded `react-native-guidelines/` files needed for the task (not web-only packs)
- [ ] DESIGN-BRIEF consulted when present (do not reinterpret visuals)

---

## Branching

- [ ] Working branch: `feature/<slug>` or `feat/<id>-<slug>`
- [ ] Based on the correct default branch (`main` / `develop` / team default)

---

## Structure and navigation

- [ ] Screens stay thin; logic in hooks/services (`structure-and-navigation.md`)
- [ ] **One** nav stack: Expo Router **or** React Navigation — no second root
- [ ] Routes/params follow existing `app/` or `navigation/` patterns
- [ ] Typed params updated when adding screens

---

## Styling, lists, config

- [ ] Styles via StyleSheet or project tokens (`styling-and-platform.md`)
- [ ] Platform splits only where behavior differs; safe area / keyboard considered
- [ ] Long data via FlatList/FlashList + stable `keyExtractor` (`lists-and-performance.md`)
- [ ] No secrets in `app.config` / committed env (`expo-config-and-env.md`)
- [ ] Identifiers and comments in **English**

---

## Accessibility and tests

- [ ] `accessibilityLabel` / role on changed interactive controls (`accessibility.md`)
- [ ] Touch targets adequate for primary actions
- [ ] RNTL (not DOM RTL) for changed screens/components (`testing.md`)
- [ ] Names: `should_<result>_when_<condition>` or repo equivalent
- [ ] Arrange / Act / Assert when the repo uses them
- [ ] Shared fixtures under test-support — do not duplicate arrange blocks

---

## Validate

```bash
npm test
```

(or `yarn test` / Expo lint/typecheck scripts from `package.json`)

- [ ] Failures in scope fixed before handoff
- [ ] `/commit` offered — do not auto-commit

---

## Prefer when matching repo

| Signal | Action |
|--------|--------|
| ARCH / CONTINUITY needs FE structure | Prefer load `../frontend-guidelines/frontend-architecture.md` |
| DESIGN-BRIEF present | Treat as acceptance; do not reinterpret visuals |
| EAS CI scripts | Prefer package.json / eas scripts over inventing new commands |
| Optional shared React hooks | Load `react-guidelines/` for hooks only — not navigation/StyleSheet |
| FlashList already installed | Prefer it for long lists; otherwise FlatList |

### Pack map (load only what you need)

| Concern | File |
|---------|------|
| Structure / nav | `structure-and-navigation.md` |
| Style / platform | `styling-and-platform.md` |
| Lists / perf | `lists-and-performance.md` |
| RNTL | `testing.md` |
| a11y | `accessibility.md` |
| Config / secrets | `expo-config-and-env.md` |

---

## References

- Pack files in this folder
- [Expo docs](https://docs.expo.dev/)
- [React Native docs](https://reactnative.dev/docs/getting-started)
- Optional hooks only: `react-guidelines/hooks-and-effects.md`
