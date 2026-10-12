# Provider authorization boundary

The Toolkit does not classify tool calls to decide whether the host may run them. ACLs, sandboxing, trust settings, and native confirmations remain owned by each provider and operator.

## Current source behavior

| Provider | Toolkit surface | Current Toolkit decision |
|----------|-----------------|--------------------------|
| Cursor | `preToolUse` and `beforeShellExecution` | Removed from the managed hook projection; stale managed entries are stripped during merge. |
| Claude Code | `PreToolUse` and `PreCompact` | Removed from the managed settings projection; stale managed entries are stripped during merge. |
| OpenCode | JS `tool.execute.before` plugin callback | Compatibility callback always allows and does not emit secret values. |
| Hermes | `pre_tool_call` plugin callback and legacy shell hook | Plugin callback allows; the legacy fail-closed shell-hook entry is removed during config merge. |
| Other PowerShell-backed providers | Existing provider-specific hook payloads | Shared evaluator always allows; unclassified tools are allowed by adapter entrypoints. |
| OpenHands shell fallback | POSIX wrapper | Allows when optional `pwsh` runtime is unavailable. |

The adapter entrypoints, event names, payloads, merge rules, and cleanup remain provider-specific. This document does not define a shared hook API.

## Validation limits

`Assert-AuthorizationPolicy.ps1` exercises the shared compatibility evaluator with an outside/temporary path, an unknown tool, and secret-shaped content. `Assert-OpenCodePathSecretsGuard.ps1` exercises the native JS evaluator. These checks establish source-level behavior only; they do not prove that a live host delivered a hook or that a host permission setting allows a particular operation.

Secret scanning is not an authorization gate. The Toolkit does not surface matched values. SDD checkpoints, dependencies, confirmation gates, and recovery remain governed by the core workflow contracts.
