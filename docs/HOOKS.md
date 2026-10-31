# Toolkit hooks

Toolkit hooks are optional helpers published by adapters. They are not the policy engine and they are not the host's permission system.

## What hooks may do

Context hooks can observe a prompt boundary, a file edit, or a compaction boundary and surface a checkpoint or compact context. They may record local state needed by the toolkit. They should be safe to skip: policy still applies when hooks are absent, disabled, unsupported, or unavailable.

## Cursor event table

Events as named by the Cursor adapter (`adapters/cursor/assets/hooks/hooks.json`). Cursor hooks are automatic and informative only; none of them decides whether a tool call runs.

| Event | Script | Purpose | Boundary |
| --- | --- | --- | --- |
| `postToolUse` | `emit-trace.ps1` | Append an allowlisted TRACE event | Fail-open; never echoes tool bodies. |
| `subagentStop` | `emit-trace.ps1` | Append an allowlisted TRACE event | Fail-open; never echoes tool bodies. |
| `beforeSubmitPrompt` | `context-before-prompt.ps1` | Track relevant skill/session intent | Always allows submit; it does not approve work. |
| `afterFileEdit` | `plan-after-edit.ps1` | Record a PLAN checkpoint | Does not validate product correctness. |

The shipped Cursor `hooks.json` publishes `preToolUse`, `beforeShellExecution`, and `preCompact` as empty arrays. Cursor has no toolkit guard.

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

## Codex and Copilot

Codex registers only `SubagentStop` -> `emit-trace.ps1`. It registers no `PreToolUse` guard and no `PostToolUse` handler. Copilot publishes an empty `hooks.json` and no active hook. Neither adapter publishes the guard files (`guard-pre-tool.ps1`, `GuardCommon.ps1`, `authorization-contract.json`); Codex publishes `_hook-common.ps1` only as the trace helper. Uninstall removes the legacy guard copies left by earlier installs. Removing the earlier `PreToolUse` guard from these two adapters is a behavior change: a malformed or identity-less event is no longer denied by a toolkit hook. See [ENFORCEMENT.md](ENFORCEMENT.md).

## Hermes

The `agent-dev-toolkit-guard` plugin registers no hook; its `register(ctx)` is a no-op kept for discovery. No `agent-hooks` files are published; uninstall removes legacy `agent-hooks` guard files from earlier installs. Publishing checks the structure of `config.yaml` before any change. An unsupported or invalid format is reported as `blocked`, and the file is left byte-for-byte intact. This is a structural check, not a YAML parser.

## Hook activation

Every adapter reports a `HookActivation` state (`manual`, `automatic`, `unavailable`, or `blocked`) when sync finishes. A hook failure does not stop sync: the run completes and then lists each failed hook with its cause. Per-adapter states are in [ADAPTERS.md](ADAPTERS.md#hook-activation).

Provider trust and review steps (for example Codex `/hooks`, Grok `/hooks-trust`, and the Cursor, Copilot, and Hermes trust steps) come from each provider's own documentation. They are manual steps for the operator. The toolkit does not perform them and this repository does not verify them.

## Hook failures in sync

A `Publish-Hooks` failure for one adapter does not stop the rest of sync. Sync prints `Hook publish failed for agent '<id>' (non-fatal, sync continues)`, runs the remaining steps, and then lists every failure under `Hook publish failures (N)` with a fix line. The run ends with `Sync completed with hook publish failures (exit code 0)`. Check that list after each sync, because the exit code does not report hook failures.

## Permission prompts are different

A host permission prompt is rendered by the host and controls whether that host will execute a particular operation. It is not a toolkit hook. A hook can report context before or after an operation, but it cannot manufacture, answer, or broaden a host permission prompt. Conversely, host approval does not satisfy a toolkit `confirm` answer (pt-BR label: `sim`) or an SDD session gate.

## Host placement

Hooks are installed only where the adapter documents them. Cursor-style hooks live under the adapter's install-root hooks directory. Claude publishes its scripts under `<InstallRoot>/hooks/` and writes the handler entries into `<InstallRoot>/settings.json`. Other hosts use their native hook/settings locations when supported. Copilot instruction placement is separate from hook placement: user mode targets the user's Copilot tree, while repo mode targets `.github/` in the consumer repository. Do not create a project-local `.cursor/hooks.json` merely to enable toolkit hooks.

## Non-goals

Hooks do not select models, classify model cost, read host session JSONL as a required dependency, implement SDD gates, or make a failed policy check pass. When a hook fails, record the limitation and continue with the portable policy path.
