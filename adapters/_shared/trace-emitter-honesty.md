# TRACE emitter honesty matrix (REQ-006 / CA6 / RNF-002)

Host-agnostic honesty for fail-open TRACE emitters. Core schema lives in
`core/skills/_shared/sdd-artifacts/TRACE-ARCHIVE-CONTRACT.md`. Adapters own
emitters only — never invent a second trail (`.agent-trace/`, git-notes SoT).

Shared helper: [`TraceEmitCommon.ps1`](TraceEmitCommon.ps1) (allowlist + fail-open + path policy).
Adapter hook copies under `assets/hooks/TraceEmitCommon.ps1` must stay byte-identical to the shared file (`Assert-TraceEmitterFailOpen` enforces SHA256 parity).

## Authorship git-notes ↔ TRACE (REQ-016…018 / WS15 / RN03)

| Concern | Rule |
|---------|------|
| **TRACE SoT** | `features/NNN-slug/TRACE.jsonl` only (append-only living-loop trail) |
| **Git-notes** | Optional **opt-in** authorship metadata (`refs/notes/toolkit-authorship`); **default off** |
| **Substitution** | Notes **never** replace TRACE (TE06). Reject any flow that treats notes as SoT |
| **Harvest / validate** | `Invoke-TraceHarvest.ps1` + `validate-trace.ps1` stay **TRACE-based** — they do not read notes |
| **Emitters** | Fail-open TRACE append unchanged; notes helper is orthogonal and does not mute emitters |

Opt-in helper + short guide: `scripts/trace/Invoke-AuthorshipGitNotes.ps1`, `docs/guides/09-authorship-git-notes.md`.
Without `-Enable`, the helper writes **no** notes (CT5).

## Matrix

| Host | Hook surface for TRACE | Wired emitter | Notes |
|------|------------------------|---------------|-------|
| **Cursor** | `postToolUse`, `subagentStop` (real) | `assets/hooks/emit-trace.ps1` via `hooks.json` | Prefer inherit; Explore Task may diverge |
| **Claude** | `PostToolUse`, `SubagentStop` (real) | `emit-trace.ps1` (+ `plan-after-edit` co-located on PostToolUse) | Merge/settings keyed upsert |
| **Codex** | Host supports PostToolUse / SubagentStop; toolkit registers `SubagentStop` only | `SubagentStop` → `emit-trace.ps1` (publisher target) | **Honesty:** no PostToolUse wire (a normal tool completion appends nothing). `SubagentStop` appends only inside `features/NNN-slug` or with `TOOLKIT_TRACE_FEATURE_ROOT`. Codex payload shape has no fixture and is not verified against a live host |
| **OpenHands** | Shell `pre_tool_use` only (limited) | — | **Honesty:** no TRACE emitter; spawn `none` → in-parent; do not fake `hooks.json` parity |
| **OpenCode** | Plugin JS hooks (`HooksSemantics=plugin-only`) | — | **Honesty:** not PS1 hook parity |
| **Hermes / Grok / Copilot / Antigravity / ZCode** | Grok, Antigravity, ZCode: PreToolUse guard shim. Hermes and Copilot: no hook registered | — | TRACE emit not claimed this wave; reuse GuardCommon path policy if added later |

## Fail-open contract

- Emitter exit **0** always; host skill continues when append fails.
- Allowlisted TRACE keys only (`ts`, `event`, `feature`, …) — never `tool_input` / bodies / secrets.
- Extra string values are redacted/truncated; dangerous Extra keys such as `response` are dropped (gate `response` belongs on curated events, not host blobs).
- Summary redaction covers GuardCommon-shaped secrets (`ghp_…`, JWT, AccountKey, connection-string fragments, bearer/api_key/password).
- **`TOOLKIT_TRACE_FEATURE_ROOT` is trusted-CI-only:** set it to an in-repo fixture `features/NNN-slug` directory for asserts/CI — never live `USERPROFILE` or untrusted operator paths (overrides cwd walk-up).
- Force-fail probe: `TOOLKIT_TRACE_FORCE_FAIL=1` → append skipped, exit still 0.
- Host shell: Cursor `hooks.json` invokes `powershell` (Windows PowerShell 5.1). Emit scripts are `#Requires -Version 5.1` and must run under `powershell` or `pwsh`; asserts prefer `powershell` then fall back to `pwsh`.

## Trace completeness

Facts, verified in the adapter code:

- The Claude adapter (`adapters/claude/Merge-ClaudeSettings.ps1`) registers `PostToolUse` with two managed handlers, `plan-after-edit` and `emit-trace`. It registers `SubagentStop` with `emit-trace`. No `PreToolUse` handler is registered; that event's managed projection is empty.
- Only `SubagentStop` writes a TRACE event (`specialist_complete`). The `emit-trace` handler on `PostToolUse` returns without writing (`TraceEmitCommon.ps1`).
- `spawn` is in the allowed event list, but no registered hook produces it.
- Whether `SubagentStop` fires for every subagent, including subagents running in the background, is host behavior. This repository does not document it.
- The Codex adapter registers only `SubagentStop`. It is not verified against a live host.
- Observed in one real run: 6 trace events for 15 subagents.

Reading rules:

- A missing trace event means unknown. It is never a failure, and it is never proof that a subagent completed or did not run.
- A trace with fewer events than known subagents is partial. Label it `partial` wherever its metrics appear.
- No metric from a partial trace may replace a review or an acceptance decision.
- Known gap: no spawn hook exists, and `SubagentStop` coverage is unverified. A `PreToolUse` spawn hook is a possible follow-up. It needs the `hook-activation` checks before it is claimed as working.

## Verify-if-missing (SEC)

- Event real vs honesty documented (this table).
- Emitter fixtures without live home (`Assert-TraceEmitterFailOpen.ps1`).
