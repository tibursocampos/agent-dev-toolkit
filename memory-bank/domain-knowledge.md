# Domain knowledge

## Bounded contexts

| Area | Description | Evidence |
|------|-------------|----------|
| Skills catalog | The toolkit has 45 invocable skills. `help-skills` presents the canonical catalog and operator notes; parity validation checks source skill IDs against the human and docs-site catalogs. | `core/skills/_shared/skills-catalog/CATALOG.md`, `core/skills/help-skills/references/present-catalog.md`, `scripts/validation/Assert-SkillCatalogParity.ps1` |
| Delivery workflows | Classic SDD handles a clear feature directly. Orchestrated Delivery uses O1 analyze, O2 deliver per story, then O3 develop; `memory-bank-init` supports the workspace context. Human approval gates remain separate from validation and implementation. | `core/skills/_shared/sdd-artifacts/PIPELINE.md`, `core/skills/orchestrate-analyze/SKILL.md`, `core/skills/orchestrate-deliver/SKILL.md`, `core/skills/orchestrate-develop/SKILL.md` |
| Agent registry and adapters | Ten registered host adapters publish the shared core. `subagents` is declared as `native` or `none`; Antigravity uses a runtime capability probe, and fallback behavior is part of the contract. | `adapters/registry.json`, `adapters/`, `core/skills/_shared/agents/SPAWN.md` |
| Storage and install | `InstallRoot` defaults to an in-repository fixture. Live user-home writes require `-AllowUserHome`. Manifest `storage_mode` selects repository or global SDD storage; feature artifacts and `memory-bank/` share the resolved root. | `README.md`, `core/skills/_shared/sdd-artifacts/STORAGE.md`, `scripts/toolkit.ps1` |
| External-access evidence | Feature 020 remains `IN_PROGRESS`. Contract and fixture checks establish scoped local behavior; they do not establish provider/host enforcement, production I/O, isolation, or TOCTOU behavior. O3 receipt paths are evidence-only, not Classic access grants. | `features/020-classic-external-access/US01/PLAN/PLAN_020_classic_external_access.md`, `core/skills/_shared/sdd-artifacts/CLASSIC-EXTERNAL-ACCESS.md` |

## Key terms

| Term | Meaning |
|------|---------|
| Core | Agent-neutral skills, policies, router, catalog, and SDD contracts. |
| Adapter | Host-specific publisher that maps the core into an install layout. |
| InstallRoot | Resolved destination for a publish; fixture-first, with profile writes gated by `-AllowUserHome`. |
| `subagents=native` / `none` | Whether a host exposes a documented Task-equivalent; `none` uses the contract's in-parent fallback. |
| O1 / O2 / O3 | Analyze, per-story specification/planning, and step-based development stages in Orchestrated Delivery. |
| Content-language | SDD prose language resolved from invocation, preferences, manifest, then chat language. |
| `external:<alias>/<path>` | Portable evidence citation; it does not authorize a filesystem root or read/write access. |
| Catalog parity | Exact equality of invocable skill IDs across source and exhaustive human/docs-site listings; descriptive README previews are not exhaustive catalogs. |

## Invariants

- A direct `sdd-develop` session executes one PLAN step and then stops. O3 has its own bounded queue and receipt contracts.
- `subagents=none` is a fallback condition, not a reason to hard-fail or invent a host capability.
- Chat follows the user's language; skill bodies and specialist prompts/receipts stay en-US; SDD artifact prose follows the content-language resolver.
- Local fixtures and assertions do not prove live host, provider, publication, or production integration behavior.
- GitHub release synchronization uses an App token with narrow contents and pull-request permissions; secret values stay in GitHub Actions, never in the repository or Memory Bank.
- SQL/database, OpenAPI/Swagger, and UI component-map contracts are not indicated by the current inventory; phase-2 Memory Bank files are therefore not required.

## Notes

Do not infer product domain names beyond the toolkit's documented agent workflow, adapters, install behavior, and SDD contracts. Record unresolved behavior in `.inventory/gaps.md`.
