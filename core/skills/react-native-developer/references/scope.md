# react-native-developer — scope

## When to prefer SDD instead

Recommend `/sdd-spec` -> `sdd-plan` -> `sdd-develop` if **two or more** apply:

| Signal | Indicator |
|--------|-----------|
| Layers | 3+ layers (screens, navigation, services, native modules) across many packages |
| API contracts | New or altered HTTP/API contracts shared across apps |
| Repos | Mobile app and another repo or service |
| Integrations | New native modules, push, deep links, or external SDKs |
| Size | 10+ files or estimated 4+ hours |
| PLAN exists | User already has an approved PLAN - use `sdd-develop` |

## DESIGN-BRIEF acceptance

If `docs/DESIGN-BRIEF.md` or `docs/design/DESIGN-BRIEF.md` exists, treat it as the acceptance source. Map sections to React Native / TSX; do **not** reinterpret visual decisions. Implement **one session scope** from section 10 only.

If the task is net-new UI without a brief, recommend `/impeccable shape` in a **new session** before implementing.
