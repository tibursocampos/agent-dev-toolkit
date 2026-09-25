# Domain knowledge

## Bounded contexts / areas

| Area | Description | Evidence |
|------|-------------|----------|
| Skills catalog | 41 invocable skills under `core/skills/*/SKILL.md`. `help-skills` loads `CATALOG.md` and `OPERATOR.md`. | `core/skills/_shared/skills-catalog/CATALOG.md` |
| Delivery path | Complete path is Orchestrated Delivery: Step 0 `memory-bank-init`, then `orchestrate-analyze`, `orchestrate-deliver` (runs `sdd-spec` then `sdd-plan` per story), `orchestrate-develop` (one `sdd-develop` child per PLAN step). Direct `sdd-spec` is the same contract when one story is already clear. `refine-story` is the O1 scorecard rubric plus a standalone invoke for one product item or open clarification B/I. | `core/skills/orchestrate-analyze/SKILL.md`, `core/skills/orchestrate-deliver/SKILL.md`, `core/skills/orchestrate-develop/SKILL.md` |
| Agent registry | 10 agents: cursor, antigravity, claude, codex, copilot, opencode, grok, zcode, hermes, openhands. Capability `subagents` is `native` or `none`. | `adapters/registry.json` |
| Spawn | Axes A (spawn vs in-parent), B (omit/inherit model), C (alternate model slug only after gate). Chat language follows the user. Spawn prompts and receipts are en-US. | `core/skills/_shared/agents/SPAWN.md`, `core/skills/_shared/agents/LANGUAGE.md` |
| Install roots | Fixture-first publish. Manifest `storage_mode` is `repository` or `global`. This bank uses repository mode at `memory-bank/`. | `README.md`, `core/sdd/STORAGE.md` |

## Key terms

| Term | Meaning |
|------|---------|
| Core | Agent-neutral skills, policy, router, and SDD contracts. |
| Adapter | Publisher that maps core into one host install layout. |
| InstallRoot | Destination tree for publish. Default is an in-repo fixture. |
| `-AllowUserHome` | Opt-in that allows a resolved `InstallRoot` under the user profile. |
| `subagents=native` | Host has a Task-equivalent spawn API. |
| `subagents=none` | No Task equivalent. Work falls back in-parent. OpenHands registry value is `none`. |
| Antigravity effective `subagents` | Probed at runtime (`ADT_ANTIGRAVITY_SUBAGENTS`, then product version). Registry value alone is not the effective value. |
| Keyed uninstall | Removes toolkit-owned files. Alien operator files and `sdd/sessions` stay. |
| Content-language | Language of written SDD artifact prose. Resolution: invocation, then `preferences.json` `artifact_language`, then manifest, else chat. |

## Invariants / rules

- One `sdd-develop` session executes one PLAN step, then stops.
- `subagents=none` (and Antigravity when the probe is not native) uses the in-parent fallback. Spawn is preference plus fallback, not a hard requirement.
- Chat output mirrors the user. Spawn prompts, receipts, and skill bodies stay en-US (`LANGUAGE.md`).
- `preferences.json` keys used by the runtime include `caveman_mode`, `caveman_level`, `orchestrator_mode`, `artifact_language`, and `verify_mode` (default false; when true, orchestrated develop spawns a read-only verifier after the implementer).
- Spec Kit, uv, and specify are not runtime dependencies. SQLite/FTS is out of scope.

## Notes

Do not invent domain names without evidence (code, README, docs).
Unknowns -> `.inventory/gaps.md`.
**No secrets / PII.**
