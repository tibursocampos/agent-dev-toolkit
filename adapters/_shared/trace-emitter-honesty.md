# TRACE emitter honesty matrix (REQ-006 / CA6 / RNF-002)

Host-agnostic honesty for fail-open TRACE emitters. Core schema lives in
`core/skills/_shared/sdd-artifacts/TRACE-ARCHIVE-CONTRACT.md`. Adapters own
emitters only — never invent a second trail (`.agent-trace/`, git-notes SoT).

Shared helper: [`TraceEmitCommon.ps1`](TraceEmitCommon.ps1) (allowlist + fail-open + path policy).
Adapter hook copies under `assets/hooks/TraceEmitCommon.ps1` must stay byte-identical to the shared file (`Assert-TraceEmitterFailOpen` enforces SHA256 parity).

## Matrix

| Host | Hook surface for TRACE | Wired emitter | Notes |
|------|------------------------|---------------|-------|
| **Cursor** | `postToolUse`, `subagentStop` (real) | `assets/hooks/emit-trace.ps1` via `hooks.json` | Prefer inherit; Explore Task may diverge |
| **Claude** | `PostToolUse`, `SubagentStop` (real) | `emit-trace.ps1` (+ `plan-after-edit` co-located on PostToolUse) | Merge/settings keyed upsert |
| **Codex** | Host supports PostToolUse / SubagentStop | Asset `emit-trace.ps1` present | **Honesty:** `Publish-CodexHooks` still emits PreToolUse guard only (PASSO 8 owns Publish-*); do not claim live PostToolUse wire yet |
| **OpenHands** | Shell `pre_tool_use` only (limited) | — | **Honesty:** no TRACE emitter; spawn `none` → in-parent; do not fake `hooks.json` parity |
| **OpenCode** | Plugin JS hooks (`HooksSemantics=plugin-only`) | — | **Honesty:** not PS1 hook parity |
| **Hermes / Grok / Copilot / Antigravity / ZCode** | Guard PreToolUse (or equivalent) where present | — | TRACE emit not claimed this wave; reuse GuardCommon path policy if added later |

## Fail-open contract

- Emitter exit **0** always; host skill continues when append fails.
- Allowlisted TRACE keys only (`ts`, `event`, `feature`, …) — never `tool_input` / bodies / secrets.
- Extra string values are redacted/truncated; dangerous Extra keys such as `response` are dropped (gate `response` belongs on curated events, not host blobs).
- Summary redaction covers GuardCommon-shaped secrets (`ghp_…`, JWT, AccountKey, connection-string fragments, bearer/api_key/password).
- **`TOOLKIT_TRACE_FEATURE_ROOT` is trusted-CI-only:** set it to an in-repo fixture `features/NNN-slug` directory for asserts/CI — never live `USERPROFILE` or untrusted operator paths (overrides cwd walk-up).
- Force-fail probe: `TOOLKIT_TRACE_FORCE_FAIL=1` → append skipped, exit still 0.
- Host shell: Cursor `hooks.json` invokes `powershell` (Windows PowerShell 5.1). Emit scripts are `#Requires -Version 5.1` and must run under `powershell` or `pwsh`; asserts prefer `powershell` then fall back to `pwsh`.

## Verify-if-missing (SEC)

- Event real vs honesty documented (this table).
- Emitter fixtures without live home (`Assert-TraceEmitterFailOpen.ps1`).
