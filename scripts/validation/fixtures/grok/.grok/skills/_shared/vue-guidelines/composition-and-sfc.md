# Vue Composition API and SFC

Vue 3 Single File Components with `<script setup>`. Absorbs prior `vue-composition` stub. For reactivity details see `reactivity.md`; for Pinia/router see `routing-and-state.md`.

---

## MUST

- Use **`<script setup lang="ts">`** for new components (TypeScript when the repo is TS).
- Declare props with `defineProps` + types; use `withDefaults` (or default values in the type syntax the project uses) for optional props.
- Declare emits with typed `defineEmits`; prefer named events over free-form strings.
- Use `defineModel` for two-way bindings when the project is on Vue 3.4+ and neighbors already use it.
- Keep SFCs focused: template + setup + scoped styles; move reusable logic into **`use*` composables**.
- Name composables `useFeatureName` and colocate with the feature or under `composables/` matching the repo.
- Composables return refs/computed/functions; components stay thin (presentation + wiring).
- Prefer explicit imports (`vue`, local components) — follow whether the project uses unplugin auto-import; do not fight it.

```vue
<script setup lang="ts">
const props = withDefaults(
  defineProps<{ title: string; size?: 'sm' | 'md' }>(),
  { size: 'md' },
);
const emit = defineEmits<{ save: [id: string] }>();
const { isSaving, save } = useOrderSave(() => props.title, emit);
</script>
```

---

## MUST NOT

- Create new Options API components on Vue 3 greenfield (`data()`, `methods`, `computed` option blocks).
- Put HTTP clients, storage, or Pinia writes directly in large template expressions.
- Grow an SFC past the project’s practical size without extracting composables/child components.
- Use `defineExpose` unless a parent/ref integration truly requires it.
- Mix Composition and Options in the same new SFC without a migration reason.
- Invent a second composable naming scheme (`helpers/`, `hooks/`) when `composables/use*` already exists.

---

## Prefer when matching repo

| Signal | Prefer |
|--------|--------|
| Options API legacy screens | Match Options API in those files; do not rewrite whole views in a small PR |
| Nuxt 3 | `script setup` + Nuxt auto-imports (`useRoute`, `useFetch`); follow `nuxt.config` layers |
| JSX / TSX Vue | Only when the project already uses `@vitejs/plugin-vue-jsx` |
| CSS modules / scoped / Tailwind | Match existing SFC style block convention |
| `defineOptions` / macros | Use when neighbors already do (Vue 3.3+) |

### SFC section order

1. `<script setup>`
2. `<template>`
3. `<style scoped>` (or project equivalent)

Match neighbors if they differ.

### Composable extraction triggers

Extract a `use*` composable when **any** apply:

- Logic is reused across two+ SFCs
- Setup block mixes fetching, form state, and keyboard handling
- Unit-testing the logic is easier without mounting the full SFC
- The SFC exceeds the project’s practical size for a single concern

Return a stable public API from the composable; avoid leaking temporary refs the parent never uses.

### Props / emits sketch

```vue
<script setup lang="ts">
const open = defineModel<boolean>('open', { default: false });
const emit = defineEmits<{ dismiss: [] }>();

function onCancel() {
  open.value = false;
  emit('dismiss');
}
</script>
```

Use `defineModel` only when Vue ≥ 3.4 and neighbors already use it; otherwise classic `prop` + `update:*` emit.

---

## References

- [Vue — `<script setup>`](https://vuejs.org/api/sfc-script-setup.html)
- [Vue — Composition API FAQ](https://vuejs.org/guide/extras/composition-api-faq.html)
- [Vue — Composables](https://vuejs.org/guide/reusability/composables.html)
- [Vue — SFC syntax](https://vuejs.org/api/sfc-spec.html)
