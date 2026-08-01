# React components and state

Structural and state rules for React (web). Absorbs clean-architecture and philosophy habits from retired stubs. For hooks/effects see `hooks-and-effects.md`; for server/async data see `data-fetching.md`. Cross-cutting a11y/tests live in hub `frontend-guidelines/` — do not duplicate those paragraphs here.

---

## MUST

- Keep presentation components focused on markup, styles, and props (including event handlers). No HTTP clients, storage, or global stores inside leaf UI files.
- Extract side effects, fetching coordination, and local state orchestration into custom hooks or feature services matching the repo layout.
- Prefer **feature / domain folders** over dumping by technical role when the repo already uses features (`features/<name>/components|hooks|services`).
- Keep state **local by default**. Lift only to the nearest common ancestor that needs it. Put values in Context/Redux/Zustand only when shared across distant screens.
- Separate **UI state** (modals, form fields, toggles) from **server/async state** (remote data, cache, mutations). Do not mirror query results into `useState` “for convenience.”
- Prefer **derived values in render** over an Effect that only copies props/state into other state (see `hooks-and-effects.md`).
- One component ≈ one UI responsibility. Split large files when they own multiple unrelated subtrees or exceed the project’s practical size (~200–300 lines of JSX/logic mixed).
- Prefer composition (`children`, slots, render props already used in the repo) over mega-config prop bags.
- Depend on interfaces/models at the component boundary; inject clients via existing providers/hooks — do not new up axios/fetch inside JSX files.
- Use **stable list keys** (entity IDs). Never use array index as `key` for lists that filter, sort, insert, or reorder.
- Identifiers, comments, and source remain English; user-facing copy follows repo i18n.

```tsx
// Prefer - UI + controller hook
export function UserProfile() {
  const { user, isLoading, handleUpdate } = useUserProfileController();
  if (isLoading) return <Spinner />;
  return <ProfileCard data={user} onSave={handleUpdate} />;
}
```

```
src/features/authentication/
  components/LoginForm.tsx
  hooks/useLoginController.ts
  services/authService.ts
  index.ts
```

---

## MUST NOT

- Put business rules, caching, or network calls directly in presentational components.
- Introduce a second global store (or parallel Context tree) when the project already standardizes on one.
- Colocate unrelated features in a single “god” component or shared catch-all folder when feature folders exist.
- Use index-as-key for mutable lists; do not “fix” remount bugs with random keys every render.
- Duplicate the same paragraph from `frontend-guidelines/` into feature code comments; load the hub file instead.
- Pass sprawling option objects that encode entire feature trees when composition/`children` already exists in the design system.

---

## Prefer when matching repo

| Signal | Prefer |
|--------|--------|
| Feature folders already present | Extend that tree; public `index.ts` barrel if the feature already exports one |
| Clean Architecture / controller hooks | Keep screens thin; logic in `use*Controller` / services |
| Design system / Blip (`blip-ds`) | Follow `blip-guidelines/` for plugin layout; still apply these state rules |
| Pages Router vs App Router | Match existing routing; do not migrate router mode in a small fix |
| CSS modules / Tailwind / CSS-in-JS | Co-locate styles with the component using the project convention |
| Form libraries (RHF, Formik) | Controlled fields via library APIs; local UI state only for non-form chrome |

### SOLID habits (React-shaped)

| Principle | Habit |
|-----------|--------|
| SRP | One distinct UI piece per component file |
| OCP | Extend via composition/`children`, not endless boolean props |
| DIP | Components depend on models/hooks, not concrete HTTP clients |

### State placement cheatsheet

| Kind | Where |
|------|--------|
| Ephemeral UI | Nearest component `useState` / `useReducer` |
| Shared in one route tree | Lift to layout / parent |
| Cross-route session UI | Existing global store / Context |
| Remote entities | Query lib / RSC / loader (`data-fetching.md`) |

---

## References

- [Thinking in React](https://react.dev/learn/thinking-in-react)
- [Managing State](https://react.dev/learn/managing-state)
- [You Might Not Need an Effect](https://react.dev/learn/you-might-not-need-an-effect)
- [rmanguinho/clean-react](https://github.com/rmanguinho/clean-react) (structure inspiration only — match the target repo first)
