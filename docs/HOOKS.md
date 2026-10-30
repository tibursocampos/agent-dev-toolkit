# Toolkit hooks

Toolkit hooks are optional helpers published by adapters. They are not the policy engine and they are not the host's permission system.

## What hooks may do

Context hooks can observe a prompt boundary, a file edit, or a compaction boundary and surface a checkpoint or compact context. They may record local state needed by the toolkit. They should be safe to skip: policy still applies when hooks are absent, disabled, unsupported, or unavailable.

## Cursor event table

Events as named by the Cursor adapter (`adapters/cursor/assets/hooks/hooks.json`).

| Event | Purpose | Boundary |
| --- | --- | --- |
| `beforeSubmitPrompt` | Track relevant skill/session intent | Always allows submit; it does not approve work. |
| `preToolUse` | Guard obvious unsafe writes/secrets where supported | Does not replace toolkit gates or host approval. |
| `afterFileEdit` | Record an artifact checkpoint | Does not validate product correctness. |
| `preCompact` | Surface context checkpoint guidance | Does not inspect private transcripts or choose a model. |

The shipped Cursor `hooks.json` publishes `preToolUse`, `beforeShellExecution`, and `preCompact` as empty arrays.

## Claude event table

Events and handlers published by the Claude adapter (`adapters/claude/assets/hooks/`, merged into `<InstallRoot>/settings.json`).

| Event | Matcher | Script | Purpose | Boundary |
| --- | --- | --- | --- | --- |
| `UserPromptSubmit` | none | `track-sdd-invocation.ps1` | Track SDD skill invocations (`use skill <id>`, `/<id>`) | Always continues the prompt; fail-open. |
| `UserPromptSubmit` | none | `preferences-command.ps1` | Handle `orchestrator` and `caveman` preference commands | Updates `sdd/preferences.json` only; fail-open, prompt continues unchanged on error. |
| `SessionStart` | none | `session-start-context.ps1` | Add the current SDD preference state as context | Context only; fail-open. |
| `PostToolUse` | `Write\|Edit` | `plan-after-edit.ps1` | Record a PLAN checkpoint | Does not validate product correctness. |
| `PostToolUse` | `Write\|Edit\|Bash\|PowerShell` | `emit-trace.ps1` | Append an allowlisted TRACE event | Fail-open; never echoes tool bodies. |
| `SubagentStop` | none | `emit-trace.ps1` | Append an allowlisted TRACE event | Fail-open; never echoes tool bodies. |

Claude has no `PreToolUse` guard hook and no `PreCompact` hook. Re-sync strips any toolkit handler left on those events from earlier installs. Permission decisions for Claude come from `permissions.allow`, `permissions.ask`, and the host sandbox, not from a toolkit hook (see [ENFORCEMENT.md](ENFORCEMENT.md)).

Exact event names and support vary by adapter. Unsupported events are simply absent.

## Permission prompts are different

A host permission prompt is rendered by the host and controls whether that host will execute a particular operation. It is not a toolkit hook. A hook can report context before or after an operation, but it cannot manufacture, answer, or broaden a host permission prompt. Conversely, host approval does not satisfy a toolkit `sim` confirmation or an SDD session gate.

## Host placement

Hooks are installed only where the adapter documents them. Cursor-style hooks live under the adapter's install-root hooks directory. Claude publishes its scripts under `<InstallRoot>/hooks/` and writes the handler entries into `<InstallRoot>/settings.json`. Other hosts use their native hook/settings locations when supported. Copilot instruction placement is separate from hook placement: user mode targets the user's Copilot tree, while repo mode targets `.github/` in the consumer repository. Do not create a project-local `.cursor/hooks.json` merely to enable toolkit hooks.

## Non-goals

Hooks do not select models, classify model cost, read host session JSONL as a required dependency, implement SDD gates, or make a failed policy check pass. When a hook fails, record the limitation and continue with the portable policy path.
