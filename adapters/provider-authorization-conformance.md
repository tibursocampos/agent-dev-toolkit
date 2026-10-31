# Provider authorization boundary

The Toolkit does not classify tool calls to decide whether the host may run them. ACLs, sandboxing, trust settings, and native confirmations remain owned by each provider and operator.

## Current source behavior

| Provider | Toolkit surface | Current Toolkit decision |
|----------|-----------------|--------------------------|
| Cursor | `preToolUse` and `beforeShellExecution` | Not projected; the shipped `hooks.json` keeps both as empty arrays. Stale managed entries are stripped during merge. |
| Claude Code | `PreToolUse` and `PreCompact` | Not projected; stale managed entries are stripped during merge. |
| Codex | `PreToolUse` guard | Not registered. Only `SubagentStop` → `emit-trace.ps1` is registered. |
| Copilot | `preToolUse` guard | Not registered; no active hook. |
| OpenCode | JS plugin | Marker plugin only; no interception callback is installed. Compatibility helpers do not gate tool calls. |
| Hermes | `pre_tool_call` | No plugin callback is registered. Legacy toolkit `pre_tool_call` entries are removed during config merge; `config.yaml` gets a structural check before any change. |
| Grok, OpenHands, ZCode, Antigravity | `PreToolUse` guard shim | Shim denies empty, malformed, or schema-invalid input (fail-closed). Its path/secret verdict comes from the shared helper, which always allows. |
| Other PowerShell-backed providers | Existing provider-specific hook payloads | Shared evaluator always allows; unclassified tools are allowed by adapter entrypoints. |
| OpenHands shell fallback | POSIX wrapper | Allows when optional `pwsh` runtime is unavailable. |

The adapter entrypoints, event names, payloads, merge rules, and cleanup remain provider-specific. This document does not define a shared hook API.

## Validation limits

`Assert-CoreContracts.ps1` and `Assert-AdapterContract.ps1` (run by `validate-core.ps1`) exercise the shared compatibility evaluator and the per-adapter guard evaluators generically across the registry, including an outside/temporary path, an unknown tool, and secret-shaped content. These checks establish source-level behavior only; they do not prove that a live host delivered a hook or that a host permission setting allows a particular operation.

Secret scanning is not an authorization gate. The Toolkit does not surface matched values. SDD checkpoints, dependencies, confirmation gates, and recovery remain governed by the core workflow contracts.
