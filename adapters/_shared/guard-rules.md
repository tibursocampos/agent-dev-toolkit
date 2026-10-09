# Shared pre-tool guard rules

Host-agnostic contract for path allow/deny and secret scanning used by adapter
`preToolUse` (or equivalent) hooks. PowerShell helpers live in
[`GuardCommon.ps1`](GuardCommon.ps1).

Cursor implements this today via `adapters/cursor/assets/hooks/guard-pre-tool.ps1`
(dot-sourcing `_hook-common.ps1`, which loads `GuardCommon.ps1`). Other adapters
should reuse `GuardCommon.ps1` and map host tool names using the table below.

## Public helpers

| Helper | Role |
|--------|------|
| `Test-ToolkitAllowedWritePath` / `Test-AllowedPath` | `$true` when relative path is allowed for write/edit |
| `Get-ToolkitSecretFindings` | Array of `{ Type, Line }` matches |
| `Test-SecretPatterns` | `$true` when any secret pattern matches |
| `Get-ToolkitNormalizedRelativePath` | Absolute/relative → workspace-relative `/` path; `$null` when outside workspace |
| `Get-WriteToolPathFromInput` | Best-effort path from host `tool_input` shapes |
| `Get-WriteToolContentFromInput` | Best-effort content from host `tool_input` shapes |
| `Test-ToolkitWriteToolName` | Cursor-oriented write/edit tool name matcher |

## Path deny (always blocked)

Evaluated before the in-workspace allow.

### Forbidden SDD locations

Legacy / non-canonical SDD trees (canonical artifacts live under `features/`):

- `PRD/**`, `PLAN/**` at repo root
- `docs/PRD/**`, `docs/PLAN/**`, `docs/backlog/**`
- `**/.cursor/plans/**`

`features/**/PLAN/**` and `features/**/PRD/**` stay allowed, including when the path is `repo/features/.../PRD/`. Root `PLAN/` and `PRD/` stay denied. A shell command with no path is allowed. A path outside the current workspace root is denied, except a shell that only runs a canonical script under `.cursor/scripts/validation`, `.cursor/scripts/session`, `.cursor/scripts/ledger`, or `.cursor/sdd`. Secret patterns stay denied.

### Denied path segments

Any path whose normalized form contains these directory segments:

| Segment |
|---------|
| `/.git/` |

Build outputs, `node_modules/`, and other workspace trees are allowed. The guard does not keep a directory or extension allowlist.

## Path allow

A write/edit is allowed when **all** of the following hold:

1. The path resolves **inside the workspace root** (see Workspace binding below).
2. The path is **not** denied above.

### Workspace binding (fail-closed)

`Get-ToolkitNormalizedRelativePath` maps paths under the workspace to a relative `/` form.
Boundary check requires `root + DirectorySeparator` (or path equal to root) — a sibling folder
whose name merely shares a prefix (e.g. `agent-dev-toolkit-evil` next to `agent-dev-toolkit`)
must **not** count as inside the workspace.

| Resolve result | Guard behavior |
|----------------|----------------|
| Inside workspace | Relative path; deny only `.git/` and legacy PRD/PLAN trees |
| User adapter home | Allow `.cursor`, `.codex`, `.claude`, `.copilot`, `.grok`, `.hermes`, `.opencode`, `.zcode`, `.antigravity`, `.gemini`, `.agents` under the user profile, plus `%LOCALAPPDATA%\hermes`. Global SDD under those homes is a write target. `.git` inside them stays denied |
| Outside workspace and outside those homes | **Deny** on write, delete, and mutating shell |
| Blank input path on write/delete | **Deny** (fail-closed; path required) |

Absolute paths outside the workspace stay denied on write and on shell that mutates a file (e.g. `C:\Temp\evil.cs` → deny). Read and execute commands are not path-gated; secret scan still runs on the command text.

Empty / unresolvable paths on write/delete: **deny** (fail-closed). Shell commands that do not mutate a file skip path checks. Redirects and `Set-Content`/`Out-File`/`Remove-Item`/`Copy-Item`/`Move-Item` still extract paths.

## Secret patterns

Line-oriented scan of write/edit content. First match per line wins. Findings expose
`Type` + `Line`.

| Type | Pattern (summary) |
|------|-------------------|
| `aws_access_key` | `AKIA` + 16 alphanumeric |
| `api_key_literal` | `api[_-]?key` assignment with ≥8 id chars |
| `github_token` | `gh[pousr]_` + ≥20 chars |
| `jwt` | three base64url segments starting with `eyJ` |
| `password_conn` | `password=` connection-style value ≥4 chars |
| `private_key` | `-----BEGIN … PRIVATE KEY-----` |
| `azure_account_key` | `AccountKey=` + ≥20 base64-ish chars |

### False-positive skips

A line is ignored when it matches (case-insensitive where noted):

`YOUR_`, `example`, `<TOKEN>`, `xxx`, `placeholder`, `Configuration[`,
`Environment.Get`, `process.env`

## Host tool-name mapping

Guards run on **write/edit**, **delete**, **shell**, and **apply_patch** when the host
wires them. Shared helper: `Get-ToolkitPathSecretsGuardVerdict`.

| Host | Write / edit / delete | Shell / terminal | Notes |
|------|----------------------|------------------|--------|
| **Cursor** | `Write`, `StrReplace`, `search_replace`, `Edit`, `MultiEdit`, `Delete` | `Shell` + `beforeShellExecution` | `guard-pre-tool.ps1`; `failClosed` |
| **Claude Code** | `Write`, `Edit` | `Bash`, `PowerShell` | PreToolUse `permissionDecision` deny |
| **Codex** | `apply_patch` (matcher also `Edit`\|`Write`) | `Bash` | Plugin `hooks.json` PreToolUse |
| **GitHub Copilot** | write/edit tools via `preToolUse` | shell via `preToolUse` | version:1 hooks JSON |
| **Antigravity / Gemini** | `write_to_file`, `replace_file_content`, `multi_replace_file_content` | `run_command` | Args: `TargetFile`, `CodeContent` / `ReplacementContent`, `CommandLine`; stdout `{ decision, reason }` |
| **Hermes** | `write_file`, `patch` | `terminal` | Plugin `pre_tool_call` `{ action: block }` + shell `agent-hooks` `fail_closed` |
| **OpenHands** | `write`, `file_editor` | `terminal` | `guard_pre_tool.sh` → decision deny + exit 2 |
| **ZCode** | `Write`, `Edit` | `Bash`, `PowerShell` | PreToolUse `permissionDecision` deny + exit 2 |
| **Grok** | `Write`, `Edit` | `Bash` | PreToolUse `decision` / `permissionDecision` deny + exit 2 |
| **OpenCode** | `write`, `edit` | `bash` | JS plugin `tool.execute.before` throw = deny |

### `tool_input` field aliases (path)

Tried in order by `Get-WriteToolPathFromInput`:

`path`, `file_path`, `filePath`, `target_file`

### `tool_input` field aliases (content)

Tried by `Get-WriteToolContentFromInput`:

`contents`, `content`, `new_string`, `newText`, `text`, plus `edits[].new_string`

## Dot-source usage

```powershell
# From adapters/<host>/assets/hooks/*.ps1 (in-repo):
. (Join-Path $PSScriptRoot '..\..\..\_shared\GuardCommon.ps1')

# Cursor published layout copies GuardCommon.ps1 next to hook scripts:
. (Join-Path $PSScriptRoot 'GuardCommon.ps1')
```

Prefer resolving via `Resolve-ToolkitGuardCommonPath` (sibling copy first, then
`adapters/_shared`).

## Cursor wiring

| Piece | Path |
|-------|------|
| Shared helpers | `adapters/_shared/GuardCommon.ps1` |
| Rules (this doc) | `adapters/_shared/guard-rules.md` |
| Cursor thin common | `adapters/cursor/assets/hooks/_hook-common.ps1` |
| Cursor pre-tool hook | `adapters/cursor/assets/hooks/guard-pre-tool.ps1` |
| Publish | copies `GuardCommon.ps1` into `<InstallRoot>/hooks/` |
