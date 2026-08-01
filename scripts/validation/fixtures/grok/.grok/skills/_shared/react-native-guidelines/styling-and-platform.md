# React Native styling and platform

StyleSheet, tokens, and iOS/Android splits. Complements `structure-and-navigation.md`.

---

## MUST

- Style with **`StyleSheet.create`** (or the project’s token / theme system: Tamagui, NativeWind, Restyle, etc.). Prefer theme tokens already in the repo over magic numbers scattered inline.
- Use Flexbox layout habits from React Native (`flex`, `alignItems`, `justifyContent`) — not browser-only CSS (web grid, cascading selectors, `rem` without a RN bridge).
- Split platforms only when behavior **truly differs**: `Platform.select`, `Platform.OS`, or `*.ios.tsx` / `*.android.tsx` / `*.native.tsx` as the repo already does.
- Respect **safe areas** (`SafeAreaView` / `react-native-safe-area-context`) for notches and home indicators when the screen touches screen edges.
- Handle **keyboard** for forms (`KeyboardAvoidingView`, `KeyboardAwareScrollView`, or project equivalent) when inputs sit near the bottom.
- Support dark/light when the app already themes via Appearance / navigation theme — extend tokens, do not hardcode one mode in new screens.
- Prefer `Pressable` / project button primitives over raw `Touchable*` when the design system already standardized.

```tsx
const styles = StyleSheet.create({
  container: {
    flex: 1,
    paddingHorizontal: spacing.md,
    backgroundColor: colors.background,
  },
  title: {
    ...typography.subtitle,
    color: colors.textPrimary,
  },
});
```

---

## MUST NOT

- Assume web CSS modules, global stylesheets, or DOM `className` without the project’s NativeWind/CSS-interop setup.
- Duplicate entire screens for iOS/Android when `Platform.select` on a few props suffices.
- Ignore safe area / status bar and draw under system UI on edge-to-edge layouts.
- Inline huge style objects recreated every render when `StyleSheet` or memoized theme styles are the project norm (measure before micro-optimizing).
- Hardcode hex colors beside an existing theme/token file for the same surfaces.

---

## Prefer when matching repo

| Signal | Prefer |
|--------|--------|
| Design tokens / theme provider | Extend theme; no one-off hex in feature code |
| NativeWind / Tamagui / unistyles | Follow that styling pipeline end-to-end |
| Different navigation headers per OS | Configure via navigator `screenOptions`, not ad-hoc Views |
| Images / icons | `expo-image` / vector icons already in package.json |
| RTL layouts | Project `I18nManager` / writing-direction tokens when already used |

### Platform split guide

| Difference | Approach |
|------------|----------|
| Padding / shadow / font | `Platform.select` in StyleSheet |
| Entire control | `Component.ios.tsx` / `Component.android.tsx` |
| Permissions / modules | Platform checks in services, not JSX soup |
| Status bar style | Existing `StatusBar` / expo-status-bar usage |

### Safe area & keyboard checklist

- [ ] Top/bottom insets applied on full-bleed screens
- [ ] Forms scroll above keyboard on both platforms
- [ ] Header + tab bar do not double-count insets incorrectly

---

## References

- [StyleSheet](https://reactnative.dev/docs/stylesheet)
- [Platform](https://reactnative.dev/docs/platform)
- [SafeAreaView / safe-area-context](https://docs.expo.dev/versions/latest/sdk/safe-area-context/)
- [KeyboardAvoidingView](https://reactnative.dev/docs/keyboardavoidingview)
