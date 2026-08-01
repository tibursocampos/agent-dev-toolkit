# React Native lists and performance

Virtualized lists and pragmatic performance for RN/Expo. Web virtualization (`react-window`) does not apply here — use RN list primitives.

---

## MUST

- Use **virtualized lists** for long or unbounded data: `FlatList`, `SectionList`, or **FlashList** (`@shopify/flash-list`) when the project already depends on it.
- Provide a stable **`keyExtractor`** (entity id). Do not use array index when the list can insert, delete, filter, or reorder.
- Keep `renderItem` light: extract row components; avoid inline huge closures that recreate heavy trees without need.
- Pass `extraData` only for values that should force row refresh; avoid putting frequently changing unrelated state into list parent scope.
- Measure before memoizing rows (`React.memo`) or rewriting list architecture — use why-did-you-render / RN perf monitor when available.
- Prefer `getItemLayout` when row height is fixed and the list is long enough that scroll-to-index matters.
- Image-heavy feeds: use the project image component (`expo-image`, FastImage, etc.) with sizing; recycle aggressively via FlashList when adopted.
- Tune `windowSize` / `maxToRenderPerBatch` / `initialNumToRender` only after observing jank — start from defaults.

```tsx
<FlatList
  data={items}
  keyExtractor={(item) => item.id}
  renderItem={({ item }) => <ItemRow item={item} />}
  windowSize={8}
/>
```

```tsx
// FlashList when already in package.json
<FlashList
  data={items}
  keyExtractor={(item) => item.id}
  renderItem={({ item }) => <ItemRow item={item} />}
  estimatedItemSize={72}
/>
```

---

## MUST NOT

- Map large arrays to `ScrollView` + children (no virtualization) for production feeds.
- Use index as `key` / `keyExtractor` for mutable lists.
- Copy web `react-guidelines/performance.md` RSC/`'use client'` guidance into RN screens.
- Prematurely add FlashList when FlatList is fine and FlashList is not a project dependency — match the repo.
- Put network fetching inside every row mount without list-level caching.
- Nest VirtualizedLists inside ScrollViews without a documented exception (virtualization breaks).

---

## Prefer when matching repo

| Signal | Prefer |
|--------|--------|
| `@shopify/flash-list` present | FlashList + documented `estimatedItemSize` |
| Infinite scroll already abstracted | Reuse hooks (`useInfiniteQuery` + list) |
| Chat / inverted lists | Match existing `inverted` / maintainVisibleContentPosition patterns |
| Small static menus | Simple map is fine; do not force FlatList for 3 items |
| Pull-to-refresh | Existing `RefreshControl` / query refetch helpers |

### Performance cheatsheet

| Symptom | First check |
|---------|-------------|
| Janky scroll | Virtualization, image size, row memo, JS thread |
| Wrong item recycle | Stable keys / `keyExtractor` |
| Jump on prepend | `maintainVisibleContentPosition` / FlashList docs |
| Blank cells (FlashList) | `estimatedItemSize` accuracy |

### Row component habits

- Accept stable props; avoid inline `() =>` handlers that break memo without need
- Do not subscribe every row to a high-churn context when a selector/store slice exists
- Keep separators / headers via list APIs (`ItemSeparatorComponent`, `ListHeaderComponent`)

---

## References

- [FlatList](https://reactnative.dev/docs/flatlist)
- [FlashList](https://shopify.github.io/flash-list/)
- [Optimizing FlatList](https://reactnative.dev/docs/optimizing-flatlist-configuration)
- [Performance overview](https://reactnative.dev/docs/performance)
