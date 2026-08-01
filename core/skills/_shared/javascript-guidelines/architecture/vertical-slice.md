# Vertical slice architecture (Node / Nest) — HOW overlay

> **Layer C (HOW).** Stack mapping only. Load principles B first: `../../code-guidelines/principles/architecture/vertical-slice.md`. Do **not** copy or restate the B essay here.
>
> Load **only** when ARCH declares vertical-slice / VSA. One style per session. VSA is **never** a silent default.

---

## Role

Map feature-first organization onto Nest feature modules (CQRS when matching) or Express/Fastify feature folders — without turning the whole repo into a new style mid-feature.

---

## MUST

- Colocate each use-case (command/query or feature folder) with its HTTP entry, validation, and handlers when the repo already uses feature folders.
- Keep cross-feature coupling low: share kernel/shared types only when neighbors already do — do not create a dumping `common/` for business rules.
- Mirror the **existing** slice shape (folder names, Nest module per feature, CQRS folders) before inventing a parallel tree.
- Keep transport mapping at the slice edge; do not push `req`/`res` into shared domain helpers.
- Cover the changed slice with the project’s test stack (unit for handlers; integration for the HTTP path).
- Keep identifiers, comments, and logs in **English**.

| Concern | Nest (when matching) | Express / Fastify (when matching) |
|---------|----------------------|-----------------------------------|
| Slice root | Feature module under `modules/` or `features/` | Feature folder with routes + services |
| Write path | Command + handler (CQRS when present) | Command/use-case module in the feature |
| Read path | Query + handler when CQRS present | Query/read module in the feature |
| HTTP | Controller in the same feature module | Router/plugin registered for that feature |

---

## MUST NOT

- Introduce VSA / feature folders into a classic concentric or layered-only tree without explicit approval.
- Force Nest CQRS (`@nestjs/cqrs`, command buses) onto Express/Fastify or onto Nest apps that do not already use CQRS.
- Glob-load every `architecture/*.md` — load **this** overlay only when ARCH names vertical-slice.
- Duplicate VSA principles from layer B inside this file.
- Share mutable feature state across slices via module globals.
- Put unrelated features’ handlers in one “god” module to save files.

---

## Prefer when matching repo

### Feature folders

- Prefer one folder (or Nest module) per feature/use-case when that layout already exists.
- Prefer colocating DTO/schema, handler, and tests beside the feature entry point.
- Prefer thin shared kernel (auth guards, logging, DB client) imported by slices — not reverse: slices must not own infrastructure bootstrap.

### Nest CQRS

- Prefer Nest CQRS **only when** `@nestjs/cqrs` (or equivalent command/query handlers) is already in the repo.
- Prefer `CommandBus` / `QueryBus` patterns that neighbor features already use — do not invent a second mediator.
- Prefer one command or query handler per use-case; keep handlers focused.

### Express / Fastify slices

- Prefer mounting a Fastify plugin or Express `Router` per feature folder.
- Prefer schema validation at the slice edge (Zod / TypeBox / Fastify schema) matching neighbors.
- Prefer keeping repositories behind the slice’s service boundary when the project already separates them.

---

## Thin HOW checklist

1. Confirm ARCH style = vertical-slice (VSA).
2. Read principles B: `vertical-slice.md` (WHAT).
3. Copy the nearest feature module/folder layout.
4. Add the new slice beside peers; wire registration the same way (Nest module import, Fastify `register`, Express `app.use`).
5. Tests live with the slice or in the project’s parallel test tree — match neighbors.

---

## Related guidelines

- Selection gate (A): `../../code-guidelines/principles/architecture-selection.md`
- Principles B: `../../code-guidelines/principles/architecture/vertical-slice.md`
- Backend defaults: `../node-backend.md`, `../node-structure-errors.md`
- Sibling overlays (load **one**): `concentric.md`, `event-driven.md`

---

## References

- [Jimmy Bogard — Vertical Slice Architecture](https://www.jimmybogard.com/vertical-slice-architecture/)
- [NestJS — CQRS](https://docs.nestjs.com/recipes/cqrs)
- [NestJS — Modules](https://docs.nestjs.com/modules)
- [Fastify — Plugins](https://fastify.dev/docs/latest/Reference/Plugins/)
