# React Native accessibility

Mobile a11y for RN/Expo. Web ARIA/DOM guidance in `react-guidelines/accessibility.md` does not map 1:1 — use RN props below.

---

## MUST

- Set **`accessibilityLabel`** (and `accessibilityHint` when the action is not obvious) on interactive controls, especially icon-only buttons.
- Set appropriate **`accessibilityRole`** (`button`, `link`, `header`, `image`, `checkbox`, …) so TalkBack / VoiceOver announce correctly.
- Reflect state with **`accessibilityState`** (`disabled`, `selected`, `checked`, `busy`) and values with **`accessibilityValue`** when relevant (sliders, progress).
- Ensure touch targets meet platform expectations (approximate **44×44** pt minimum) for primary actions.
- Keep focus order sensible for screen readers; group related text with `accessible={true}` on containers only when it improves the announcement (avoid over-grouping).
- Prefer testing via RNTL queries that use label/role so labels stay honest (`testing.md`).
- Support Dynamic Type / font scaling: avoid fixed heights that clip text when `allowFontScaling` is on (default).
- Mark decorative images appropriately; give meaningful labels to informative images.

```tsx
<Pressable
  accessibilityRole="button"
  accessibilityLabel="Close"
  accessibilityHint="Dismisses the dialog"
  accessibilityState={{ disabled: isBusy }}
  onPress={onClose}
>
  <CloseIcon />
</Pressable>
```

---

## MUST NOT

- Ship icon-only controls with no `accessibilityLabel`.
- Block font scaling globally without an explicit product decision.
- Rely on color alone for state (error, selected) — add text or icons.
- Leave important information only in images without labels.
- Copy web `aria-*` attributes expecting them to work unchanged on all RN targets without the project’s a11y bridge.
- Set `accessible={true}` on large trees that swallow child labels needed individually.

---

## Prefer when matching repo

| Signal | Prefer |
|--------|--------|
| Design system mobile kit | Use DS a11y props; do not reimplement tabs/modals from scratch |
| Forms | Associate labels with inputs the way the DS documents |
| Lists | Label rows meaningfully (`Item, status`) not only “button” |
| Alerts / toasts | Existing announcement patterns (DS / library) |

### Checklist while coding

- [ ] Label + role on every new interactive control
- [ ] Disabled/selected reflected in `accessibilityState`
- [ ] Touch target large enough for primary actions
- [ ] RNTL can `getByLabelText` / role-query the control
- [ ] Font scaling does not clip critical text

### Common pitfalls

| Pitfall | Fix |
|---------|-----|
| Icon-only `Pressable` | `accessibilityLabel` |
| Custom switch | `accessibilityRole="switch"` + `accessibilityState.checked` |
| Row announces twice | Avoid double labeling parent + child |
| Tiny hit slop | Increase padding / `hitSlop` |

---

## References

- [React Native Accessibility](https://reactnative.dev/docs/accessibility)
- [Expo Accessibility](https://docs.expo.dev/guides/accessibility/)
- [Android accessibility](https://developer.android.com/guide/topics/ui/accessibility)
- [Apple VoiceOver](https://developer.apple.com/accessibility/ios/)
