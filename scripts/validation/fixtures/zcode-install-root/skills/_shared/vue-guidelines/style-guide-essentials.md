# Vue style guide essentials

Priority rules from the official Vue style guide. Cross-cutting a11y lives in `accessibility.md` and hub `frontend-guidelines/` — do not duplicate full essays here.

---

## MUST

### Priority A (essential)

- Always provide a **`:key`** on `v-for` with a **stable unique id** (entity id). Do not use array index when the list can filter, sort, insert, or reorder.
- **Never** use `v-if` and `v-for` on the **same element**. Prefer wrapping with `<template v-for>` and putting `v-if` on an inner node, or filter the list in `computed`.
- Use **component `name`** (or SFC filename that implies name) consistent with multi-word component names when the project enforces them.
- Prop definitions must be as detailed as practical (type, required, default) — typed `defineProps` satisfies this in `<script setup>`.
- Keep component data / refs that belong to the instance **local**; do not mutate props.

```vue
<!-- Correct -->
<template v-for="item in visibleItems" :key="item.id">
  <Row v-if="item.active" :item="item" />
</template>

<!-- Wrong: v-if + v-for on same node; index key on mutable list -->
<li v-for="(item, i) in items" v-if="item.active" :key="i">
```

### Component naming

- Multi-word component names in userland (avoid clashing with HTML elements): `UserCard`, `OrderList`.
- Base/presentational prefixes match the repo (`Base*`, `App*`, `Ui*`).

---

## MUST NOT

- Ship Priority A violations in new or touched lists/conditionals.
- Use `key` on bare `<template v-if>` branches inconsistently when siblings need stable identity — follow Vue docs for conditional reuse.
- Mutate prop objects/arrays in child components; emit events or use `defineModel` per project style.
- Use non-descriptive component names (`Todo`, `Item`, `List`) when the style guide / linter requires multi-word.

---

## Prefer when matching repo

| Signal | Prefer |
|--------|--------|
| ESLint `vue/essential` / `vue/recommended` | Fix lint violations rather than disabling rules |
| Priority B/C style guide items | Apply when neighbors already follow them (attribute order, self-closing, etc.) |
| Single-file vs class components | SFC Composition API default |
| Scoped vs module CSS | Match existing |

### Priority B highlights (when matching repo)

- Element attribute order roughly: `is` → `v-for` → `v-if`/`v-else-if`/`v-else` → `v-show` → `v-cloak` → `v-pre` → `v-once` → `id` → `ref` → `key` → others… (follow eslint-plugin-vue if configured).
- Prefer detailed prop definitions and sensible defaults over loosely typed props.
- Prefer self-closing components (`<MyComp />`) when the project’s eslint rule requires it.
- Keep `v-bind` object syntax consistent with neighbors (`v-bind="attrs"` vs explicit props).

### List key decision

| List behavior | Key |
|---------------|-----|
| Static list never reordered | Stable id still preferred |
| Filter / sort / insert / delete | **Entity id** required |
| Pure ephemeral UI chips without ids | Generate stable ids at creation time — do not use index |

### v-if / v-for separation examples

```vue
<!-- Prefer: filter in computed -->
<li v-for="item in activeItems" :key="item.id">{{ item.name }}</li>

<!-- Prefer: template wrapper -->
<template v-for="item in items" :key="item.id">
  <li v-if="item.visible">{{ item.name }}</li>
</template>
```

Never “fix” Priority A by disabling eslint without a documented exception.

---

## References

- [Vue — Style Guide (Priority A)](https://vuejs.org/style-guide/rules-essential.html)
- [Vue — Style Guide (Priority B)](https://vuejs.org/style-guide/rules-strongly-recommended.html)
- [Vue — List rendering](https://vuejs.org/guide/essentials/list.html)
- [eslint-plugin-vue](https://eslint.vuejs.org/)
