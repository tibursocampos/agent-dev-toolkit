# blip-plugin-developer — Phase 3 handoff

### Phase 3 - Handoff (implementation)

When scaffolded code or handoff notes touch source: discover architectural patterns; follow `structure-and-quality.md` §1 (operator order and the established project style outrank the toolkit style bar; do not restyle existing members without an explicit yes) plus Blip/React overlays; on greenfield / no clear comment-language mirror, ask before writing narrative comments/docs (identifiers stay English).

Ask in the **user chat language** what to implement next. Route by scope:

| Scope | Next step |
|-------|-----------|
| Net-new UI / redesign | Create `docs/DESIGN-BRIEF.md` with `target_stack: react` and Blip/BDS notes in section 9, then hand off to `react-developer` |
| Plugin implementation | `/react-developer` (auto-loads `blip-guidelines/` when `blip-ds` present) |
| Backend API (.NET) | `/dotnet-developer` in **separate repo** - not in plugin scaffold session |

**DESIGN-BRIEF:** write a project-specific brief using `{{TOOLKIT_ROOT}}/skills/_shared/frontend-guidelines/frontend-practices.md` as general guidance. Keep substantial design discovery and implementation in separate sessions.

**External API:** if Phase 1 answer was REST backend, remind user to read `external-api-integration.md` during `react-developer` sessions.

## Complexity profiles

Choose by technical criteria only — not by historic repo names.

| Profile | Criteria |
|---------|----------|
| **Lite** | Single route, BDS web components, no AuthProvider, minimal or no permission gates |
| **Full** | Multi-route, AuthProvider, buckets, `blip-ds-react` (or equivalent wrappers), segment tracking as needed |

Load `auth-and-permissions.md` only for Full profile.
