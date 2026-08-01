# Vue delivery checklist

Use before opening a pull request. Prefer Vue 3 + `<script setup>` + Pinia on greenfield; otherwise match the project.

When ARCH or CONTINUITY needs frontend folder layout, load `../frontend-guidelines/frontend-architecture.md` (shared hub: feature-first `app` / `features` / `shared`) — do not invent a full Clean Architecture tree inside this Vue pack.

---

## Preparation

- [ ] `AGENTS.md` / README and relevant skills reviewed
- [ ] PLAN step (if applicable) understood
- [ ] Acceptance criteria clear
- [ ] Vue 3 / Nuxt / router / Pinia vs Vuex confirmed from the repo

---

## Branching

- [ ] Working branch: `feature/<slug>` or `feat/<id>-<slug>`
- [ ] Based on the correct default branch (`main` / `develop` / team default)

---

## Implementation

- [ ] New SFCs use `<script setup>` (Options API only for legacy files)
- [ ] Priority A: `:key` on `v-for`; never `v-if` + `v-for` on the same node
- [ ] Logic extracted into `use*` composables when reused or oversized
- [ ] Pinia stores by domain (or Vuex modules if legacy)
- [ ] Routes named + lazy-loaded when neighbors already split code
- [ ] Derived state via `computed`; watchers cleaned up
- [ ] a11y: semantics, labels, keyboard for touched UI
- [ ] Identifiers and comments in **English**
- [ ] Changes follow `vue-guidelines` (load files needed for the task)

---

## Tests (new or changed behavior)

- [ ] Vitest (or project runner) + Arrange / Act / Assert
- [ ] Fresh Pinia per test when stores involved
- [ ] Behavior assertions (emits / DOM), not only snapshots
- [ ] `vue-tsc --noEmit` (or project typecheck) when TS is enabled

---

## Build

```bash
npm test
npm run build
vue-tsc --noEmit
```

(or project-equivalent scripts)

- [ ] Targeted tests green for changed code
- [ ] Production build succeeds when required by the task

---

## Prefer when matching repo

| Signal | Action |
|--------|--------|
| ARCH / CONTINUITY needs FE structure | Prefer load `../frontend-guidelines/frontend-architecture.md` |

---

## Before PR

- [ ] Diff limited to stated acceptance (YAGNI)
- [ ] No new state libraries without need
- [ ] Conventional commit message ready (via `/commit` when requested)
- [ ] Guideline paths touched: `composition-and-sfc`, `style-guide-essentials`, `reactivity`, `routing-and-state`, `testing`, `accessibility` as applicable

### Quick verify

- Priority A: keys + no `v-if`/`v-for` same node on touched lists
- Pinia domain boundaries respected (no god store growth)
- a11y keyboard pass on new interactive SFCs
- `npm test` / typecheck / build as required by the task

---

## References

- [Vue — Style Guide (Priority A)](https://vuejs.org/style-guide/rules-essential.html)
- [Vue — `<script setup>`](https://vuejs.org/api/sfc-script-setup.html)
- [Pinia — Introduction](https://pinia.vuejs.org/introduction.html)
- [Vue — Accessibility](https://vuejs.org/guide/best-practices/accessibility.html)
