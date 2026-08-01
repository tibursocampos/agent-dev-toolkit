# Vue 3 Composition API

Standards for Vue 3 with `<script setup>`. Match project conventions (Pinia, Vue Router versions).

## Script setup

- Use `<script setup lang="ts">` for new components.
- `defineProps` / `defineEmits` with TypeScript types; prefer `withDefaults` for optional props.
- `defineModel` when the project uses v-model bindings on components (Vue 3.4+).

```vue
<script setup lang="ts">
const props = withDefaults(defineProps<{ title: string; size?: 'sm' | 'md' }>(), {
  size: 'md',
});
const emit = defineEmits<{ save: [id: string] }>();
</script>
```

## Reactivity

- `ref` for primitives and reassignable values; `reactive` for stable object shapes when the project already uses it.
- `computed` for derived state - do not duplicate logic in templates.
- `watch` / `watchEffect` for side effects; prefer `watch` with explicit sources.
- Use `shallowRef` / `markRaw` for large non-reactive objects when needed.

## Composables

- Extract reusable logic into `use*.ts` composables (data fetching, form state, keyboard shortcuts).
- Composables return refs/computed; components stay thin.
- Name composables `useFeatureName` and colocate with the feature or under `composables/`.

## Provide / inject

- Use for deeply nested dependency injection (theme, auth context) - sparingly.
- Prefer Pinia stores for shared application state.

## Templates

- Keep templates readable; move complex expressions to computed properties.
- Use `v-for` with `:key` (stable IDs, not index when list mutates).
- Prefer `@click` handlers over inline logic for non-trivial actions.

## Lifecycle

- `onMounted` / `onUnmounted` for DOM subscriptions and timers.
- Clean up listeners and intervals in `onUnmounted`.
