# blip-plugin-developer — Phase 3 handoff

### Phase 3 - Handoff (implementation)

Ask **(pt-BR)** what to implement next. Route by scope:

| Scope | Next step |
|-------|-----------|
| Net-new UI / redesign | `/impeccable shape` -> `docs/DESIGN-BRIEF.md` with `target_stack: react` and Blip/BDS notes in section 9 |
| Plugin implementation | `/react-developer` (auto-loads `blip-guidelines/` when `blip-ds` present) |
| Backend API (.NET) | `/dotnet-developer` in **separate repo** - not in plugin scaffold session |

**DESIGN-BRIEF:** use template at `{{TOOLKIT_ROOT}}/skills/impeccable/reference/DESIGN-BRIEF-TEMPLATE.md`. One session = design **or** implementation, not both.

**External API:** if Phase 1 answer was REST backend, remind user to read `external-api-integration.md` during `react-developer` sessions.

## Complexity profiles

Choose by technical criteria only — not by historic repo names.

| Profile | Criteria |
|---------|----------|
| **Lite** | Single route, BDS web components, no AuthProvider, minimal or no permission gates |
| **Full** | Multi-route, AuthProvider, buckets, `blip-ds-react` (or equivalent wrappers), segment tracking as needed |

Load `auth-and-permissions.md` only for Full profile.
