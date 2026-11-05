# Subagent options reference

Common contract for adapter-specific model and effort options used by `orchestrate-*` and `developer` session selection (US01), and by `adt-settings` (US02). This contract is orthogonal to `SPAWN.md`, which governs when to delegate, and `SUBAGENT-MODEL.md`, whose default is to omit `model` and inherit from the parent.

Install path after sync: `{{TOOLKIT_ROOT}}/skills/_shared/agents/SUBAGENT-OPTIONS.md`

## Scope and non-goals

This file defines provenance and consumption rules for adapter options; it is not a fixed model catalog or a generic settings registry. It adds no roles, favorites, editable support flags, hooks, commands, modes, `hostCeiling`, `spawn_limits`, `SettingsRegistry`, or adjustable limits. It does not configure the parent's model. A model name, plan, or `subagents=native` capability does not prove that an option is available or supported.

## Pair contract

The internal selection is always a complete `{model, effort}` pair. `inherit` is a user-interface choice and is never persisted as a string. Unless the complete pair is supported by the effective adapter surface, omit both arguments and any composite field that would encode them, then inherit the parent's model and effort. The internal pair does not require adapters to use identically named native arguments.

## Preference shape

The only new preference is `subagent_models.default`: complete `{model, effort}` object or absent. Absent means inherit; inherit is never persisted as a string. Reading never writes or migrates preferences. An invalid default is ignored without deleting content or echoing it; any warning names only the field and reason. Reset removes only `default` and preserves unrelated keys. A saved selection may preselect the session question but never answers it.

When US02 saves a value and the preferences file is absent, it uses the existing structure from `scripts/_lib/Initialize-SddPreferences.ps1` (`New-ToolkitDefaultPreferencesObject`) and adds the new key only with a value to save. It does not invent a file format. The installer does not seed `subagent_models` (`NO_CHANGE`).

## Evidence states

`DOCUMENTED` means primary documentation was consulted. `SESSION_SCHEMA` means a tool signature was exposed in the identified session context. `RUNTIME_VERIFIED` requires real execution evidence. `UNKNOWN` records a gap and the consultation needed to resolve it. Documentation, schemas, fixtures, and publication do not establish runtime application. A child agent's self-report does not prove the model or effort actually applied.

## Adapter matrix

| Adapter row | Surface / version | Option source | Pair encoding | Native mechanism and restrictions | Fork / precedence | Parent question | Evidence state | Consulted on |
|---|---|---|---|---|---|---|---|---|
| ADP-CLAUDE | Claude Code; installed version and managed restrictions must be recorded. | Inspect `/model` without changing the parent; cross-check the official [sub-agent](https://code.claude.com/docs/en/sub-agents) and [model configuration](https://code.claude.com/docs/en/model-config) documentation. Do not freeze aliases or IDs in the toolkit. | Documentation distinguishes model and effort per invocation; per-call effort requires a compatible version and a non-fork subagent. | Check the effective schema and availability; environment or managed policy may override. Do not change the fork type to force support. | Verify session/fork restrictions and environment or policy precedence; current effective schema is unknown. | `/tasks` records model and effort when present. The parent uses a verified question component only when the selected answer returns; otherwise use numbered text options. | DOCUMENTED; installed version, allowed catalog, effective schema, and execution UNKNOWN. | 2026-11-02 |
| ADP-CODEX | Distinguish Codex CLI, extension, and app; this row's schema evidence is limited to the identified session. | Inspect the schema of the tool actually exposed and the options permitted by the current client/account. Official [subagent](https://learn.chatgpt.com/docs/agent-configuration/subagents) and [configuration](https://learn.chatgpt.com/docs/config-file/config-reference) documents are references, not an account catalog. | This session schema exposes `model` and `reasoning_effort`; availability of an alternate complete pair is not established by that signature. | `collaboration.spawn_agent` also exposes `fork_turns`. Configuration fields do not prove ephemeral per-call support; do not rewrite agents by role or change fork/history. | Preserve the selected parent context; exact account and runtime precedence remain unknown. | Use the question surface actually exposed to the parent and only if the selected answer returns; otherwise use numbered text options. | DOCUMENTED and SESSION_SCHEMA for the identified session; account availability and alternate execution UNKNOWN. | 2026-11-02 |
| ADP-CURSOR | Distinguish Cursor Agent from the editor and CLI; client, plan, and admin context matter. | Inspect the effective picker/context and the official [subagents](https://cursor.com/docs/subagents) documentation linked to its model reference. Do not treat examples as an available catalog. | Documentation describes `id[effort=value]`; the effective client schema and option availability are unknown. | Availability depends on model and plan/admin policy. An agent definition does not prove spawn arguments. Do not change profiles or context/speed settings to force support. | Recheck client schema, fork behavior, eligibility, and precedence for the active surface; otherwise record UNKNOWN. | Use a verified parent question component only when its answer returns; otherwise use numbered text options and wait. | DOCUMENTED; client schema, effective options, and execution UNKNOWN. | 2026-11-02 |
| ADP-HERMES | Identify the installed version, profile, and `delegate_task` schema. | Inspect existing route configuration read-only and the official [advanced delegation](https://hermes-agent.nousresearch.com/docs/plugins/advanced-delegation) documentation. With no configured routes, do not invent options or install a plugin. | Existing `model_map` or `profile_routes` select an `option` or profile; there is no documented universal free-form pair. | Standard delegation differs from existing routed selection. A route that also changes credentials, skills, or identity does not satisfy this contract. Do not configure a backend, profile, or mode. | Use only an existing compatible route and verify its effective precedence; absent or incompatible routes mean inherit. | Use the current parent question mechanism only when a selection returns; otherwise use numbered text options. | DOCUMENTED; installation, routes, effort support, and execution UNKNOWN. | 2026-11-02 |
| ADP-COPILOT | Record CLI, IDE/VS Code, or cloud separately; evidence does not transfer between surfaces. | For CLI, inspect the read-only model picker and official [CLI reference](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference). Other surfaces need their own documentation and schema. | CLI documentation names `model`/`models` and `reasoningEffort`; examples are not a universal closed catalog. | Confirm actual tool arguments and precedence by-call, configuration, definition, and parent; the Auto-session exception matters. Fallback does not prove the requested pair. Do not set `required` or alter the parent model. | Never use CLI evidence for IDE/cloud. Account, per-call schema, and runtime remain unknown. | Use a verified parent question component only when the selected answer returns; otherwise use numbered text options and wait. | DOCUMENTED for CLI only; account, per-call schema, and execution UNKNOWN; IDE/cloud UNKNOWN. | 2026-11-02 |

The canonical project matrix remains the adapter matrix in the TS02 ANALYSIS; this file transports that contract without copying historical model slugs.

## Consumption rules

- US01 and `adt-settings` use the same ADP row for the effective surface and the same eligible pairs.
- A client, version, surface, policy, or route change requires eligibility to be checked again; do not add an editable support cache.
- The parent asks once at session start, and the answer applies to all subagents. A question is never repeated for each spawn (D-032).
- Non-interactive sessions and O3 continuous/queued work use the session choice made at the start. Missing or unreadable configuration means omit both arguments and inherit.
- If the host refuses a pair, including a repeated request for that pair, re-evaluate eligibility once, then inherit the current session parent's full pair and continue the task. Failure never stops the work (D-035).
- Validation of an alternate pair is manual by the operator; the agent never performs it automatically (D-031).

## Related contracts

- `SUBAGENT-MODEL.md`
- `SPAWN.md`
- `QUESTIONS.md`
- `RECEIPT.md`
