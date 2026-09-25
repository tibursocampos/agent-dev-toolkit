# Domain: CLI scripts

Operator entry points under `scripts/`.

## Scripts

| Script | Role |
|--------|------|
| `scripts/toolkit.ps1` | Interactive Smart Manager (wizards + Help) or `-Action` / `-Agent` orchestrator |
| `scripts/sync-agent.ps1` | Load registry module; run `Publish-Skills`, `Publish-Policy`, `Publish-Router`, `Publish-Agents`, `Publish-Hooks`, then always `Get-SddRoot -Prepare` |
| `scripts/bootstrap/bootstrap.ps1` (+ `.bat` / `.sh`) | Option 0 Release bootstrap: HTTPS zip → SHA256 → extract → `toolkit.ps1` (fixed assets `agent-dev-toolkit.zip` / `.sha256` — [INSTALL § 0](../INSTALL.md#0-release-bootstrap-https--checksum--toolkit)) |
| `scripts/validate-agent.ps1` | Runs `validate-core` by default, then adapter `Invoke-SmokeValidate`; skips core only with `-SkipCore` |
| `scripts/validation/validate-core.ps1` | Core contract suite (alias `validate-all.ps1`) |
| `scripts/validation/Invoke-*CiSmoke.ps1` | CI-parity smoke harnesses |
| `scripts/inventory/Invoke-MemoryBankInventory.ps1` | Read-only bank inventory (`ready` \| `not-ready`) |
| `scripts/validation/Invoke-PrdPlanChangePreflight.ps1` | PRD → PLAN → CHANGE preflight before O3 |
| `scripts/trace/Invoke-TraceHarvest.ps1` | Feature-scoped TRACE harvest |
| `scripts/trace/Invoke-AuthorshipGitNotes.ps1` | Opt-in authorship git-notes (default off; never TRACE SoT) — [guide 09](../guides/09-authorship-git-notes.md) |
| `scripts/ledger/Invoke-PlanLedgerClaim.ps1` | PLAN-LEDGER claim / status / release |
| `scripts/session/Invoke-DevelopSessionGate.ps1` | Idempotent develop `step_confirmed` (WS10) |
| `scripts/validation/Invoke-SiblingReadinessGate.ps1` | Selective clarify READY / NEEDS_CLARIFICATION (WS3) |

Shared helpers: `scripts/_lib/` (`Resolve-InstallRoot`, `Resolve-RegistryAgent`, toolkit constants, …).

## Shell allowlist tip (WS10 / REQ-013)

For O3 / Classic develop, skills **MUST** invoke the canonical scripts with `-File` (not inline session JSON). Prefer host **opt-in** allowlist of these two portable paths (cwd = repo root) so one Shell approve can chain both calls:

1. `scripts/session/Invoke-DevelopSessionGate.ps1`
2. `scripts/ledger/Invoke-PlanLedgerClaim.ps1`

Sessions root: `~/.cursor/sdd/sessions` (or `$SDD_ROOT/sessions`). **RNF-004:** do not auto-approve all Shell; do not mutate hooks policy silently; path/secrets guards stay intact. Cursor detail: [adapters/cursor/README.md](../../adapters/cursor/README.md) § Shell allowlist.

## Operator workflow (inventory → preflight → develop → harvest)

Same skill call flow; these scripts add deterministic gates/evidence — not a second toolkit CLI.

| Order | Script | Exit / status |
|-------|--------|---------------|
| 1. Inventory | `Invoke-MemoryBankInventory.ps1` | `0` = `ready`; `2` = `not-ready` (writes only under `memory-bank/.inventory/`) |
| 2. Preflight | `Invoke-PrdPlanChangePreflight.ps1` | `0` allow; `1` usage; `2` block (read-only; runs validate-prd/plan/change) |
| 3. Develop | Classic SDD / O3 (`Invoke-DevelopSessionGate` + `Invoke-PlanLedgerClaim`) | SESSION gates + ledger hold (allowlist tip above) |
| 4. TRACE harvest | `Invoke-TraceHarvest.ps1` | `0` ok; `2` fail (reads **only** `features/NNN-slug/TRACE.jsonl`) |

Contracts (do not paste full schema here): [TRACE archive](core.md#trace-archive-living-loop), [PLAN-LEDGER](core.md#plan-ledger--develop-session-gate), [VALIDATION.md](../VALIDATION.md).

### Memory-bank inventory

```powershell
pwsh -NoProfile -File .\scripts\inventory\Invoke-MemoryBankInventory.ps1 `
  -RepoPath . -BankPath .\memory-bank -AllowCreateInventory
```

- Scans the consumer repo; updates `memory-bank/.inventory/sources.json` (path, `last_write_utc`, length, sha256, short summary).
- Emits inventory-level `inventory_hash`, `inventory_summary`, and `status` `ready` \| `not-ready` (+ `status_reason`).
- **Portable paths only** in `sources.json` (`repo_path`, `bank_path`, and each source `path`) — never OS absolute / machine-local roots.
- Never modifies application source. Secret-named leaves get a redacted summary heuristic.
- Assert smoke: `scripts/validation/Assert-MemoryBankInventory.ps1` (wired in `validate-core`).

### Sibling readiness (selective)

```powershell
pwsh -NoProfile -File .\scripts\validation\Invoke-SiblingReadinessGate.ps1 `
  -FeatureRoot features\<NNN-slug>\<story>
```

Evaluates open clarification markers (B / I / MINOR) per `readiness-severity.md` under that feature/story root. Open **B**/**I** → exit `NEEDS_CLARIFICATION` (blocks O2 / refine handoff as READY). Presence of sibling folders alone is not READY. Assert: `Assert-SiblingReadinessGate.ps1`. Domain: [core readiness](core.md#clarification-readiness-b--i--minor).

### PRD / PLAN / CHANGE preflight

```powershell
pwsh -NoProfile -File .\scripts\validation\Invoke-PrdPlanChangePreflight.ps1 `
  -FeatureRoot features\<NNN-slug> `
  -PlanPath features\<NNN-slug>\<story>\PLAN\PLAN_....md
```

Deterministic only — no LLM. Invokes structural validate-prd / validate-plan / validate-change; blocks O3 with an explicit reason when inconsistent. Optional `-PrdPath`, `-ChangePath`, `-Nature`.

### TRACE harvest

```powershell
pwsh -NoProfile -File .\scripts\trace\Invoke-TraceHarvest.ps1 `
  -FeatureRoot features\<NNN-slug>
```

Summarizes events from that feature’s `TRACE.jsonl` only (includes `tokens` / `duration` / `spawn` when present). Path escape or sessions-root reads fail explicitly — never dumps `sdd/sessions`. Assert: `Assert-TraceHarvest.ps1`.

### PLAN-LEDGER CLI

```powershell
pwsh -NoProfile -File .\scripts\ledger\Invoke-PlanLedgerClaim.ps1 `
  -Action claim -PlanPath features\<...>\PLAN\PLAN_....md -Step 2 -Holder <id> `
  -RepoPath . -SessionsRoot <sessions-root>
```

See [core.md PLAN-LEDGER + session gate](core.md#plan-ledger--develop-session-gate).

```powershell
pwsh -NoProfile -File .\scripts\session\Invoke-DevelopSessionGate.ps1 `
  -PlanPath features\<...>\PLAN\PLAN_....md -RepoPath . -SddRoot <sdd-root>
```

Assert: `Assert-DevelopSessionGate.ps1` (also checks allowlist docs cite both scripts).

## toolkit.ps1

```powershell
pwsh -NoProfile -File .\scripts\toolkit.ps1
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action ListAgents
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Validate -Agent cursor
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent cursor -WhatIf
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Uninstall -Agent claude -WhatIf
pwsh -NoProfile -File .\scripts\toolkit.ps1 -Action Sync -Agent codex -UserScope -AllowUserHome -InstallRoot "$env:USERPROFILE\.codex"
```

Interactive menu: Sync / Validate / Sync+Validate / Validate core / Validation lab / Uninstall / Help. Sync / Validate / Uninstall require an explicit agent id (wizard or `-Agent`; no silent home default).

`-Mode` is forwarded to sync, validate, and uninstall. For `-Agent copilot` it is required and must be `user` or `repo`. `-AllowUserHome` is forwarded the same way and is the opt-in when `InstallRoot` resolves under the user profile. Optional `-UserScope` is forwarded to `sync-agent.ps1` for adapters that declare `Publish-Skills -UserScope` (Codex). It is opt-in only.

`-WhatIf` forwards to `sync-agent.ps1` for Sync / SyncAndValidate, and to adapter `Uninstall-Toolkit` when that command declares `-WhatIf`.

Uninstall stays keyed. `toolkit.ps1` loads the selected adapter and calls `Uninstall-Toolkit`, which removes known toolkit artifacts only. It does not wipe `InstallRoot`.

Backup stays a non-interactive fail-closed stub (`-Action Backup` only; it is not on the interactive menu). `Invoke-ToolkitStubAction` does not call an adapter. It reports that Backup is not implemented and refuses a success exit. `-ForceStub` is the only success path, and only for tooling tests that acknowledge the stub. It is not a real backup.

## sync-agent.ps1

```powershell
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent <id> [-InstallRoot <path>] [-Mode user|repo] [-AllowUserHome] [-UserScope] [-WhatIf]
```

| Parameter | Behavior |
|-----------|----------|
| `-Agent` | Required registry id |
| `-InstallRoot` | Target root for `Publish-*`. `toolkit.ps1` interactive target wizard defaults to live home. `sync-agent.ps1` with no `-InstallRoot` defaults to the in-repo fixture (Copilot fixture follows `-Mode`) |
| `-Mode` | Required for `-Agent copilot`: `user` \| `repo` (TE02 when missing or invalid). Ignored for other agents |
| `-AllowUserHome` | Opt-in when `InstallRoot` resolves under the user profile |
| `-UserScope` | Optional. Forwarded to `Publish-Skills` when the adapter declares `-UserScope` (Codex). Opt-in mirror to `~/.agents/skills`. Leave it off by default: Codex already discovers `InstallRoot/skills` (`~/.codex/skills`); dual mirrors duplicate `$` picks |
| `-WhatIf` | Forwarded to `Publish-*` when those commands declare `-WhatIf` |

Publish order: `Publish-Skills` → `Publish-Policy` → `Publish-Router` → `Publish-Agents` → `Publish-Hooks`, then always `Get-SddRoot -Prepare` (sessions directory, and seed `manifest.json` only when missing; never overwrites an existing manifest or clears sessions). A stub module that returns `Implemented = false` makes sync exit non-zero without writing under the user profile.

## validate-agent.ps1

```powershell
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent <id> [-InstallRoot <path>] [-Mode user|repo] [-AllowUserHome] [-SkipCore] [-SkipSmoke]
```

| Parameter | Behavior |
|-----------|----------|
| `-Agent` | Required registry id. Missing `-Agent` fails |
| `-InstallRoot` | Fixture root for smoke. Defaults to the in-repo fixture (Copilot fixture follows `-Mode`) |
| `-Mode` | Required for `-Agent copilot`: `user` \| `repo` (TE02 when missing or invalid). Ignored for other agents |
| `-AllowUserHome` | Opt-in when `InstallRoot` resolves under the user profile |
| `-SkipCore` | Skip `scripts/validation/validate-core.ps1`. Local default still runs core. Use this only when the caller already ran core (CI ephemeral smoke) |
| `-SkipSmoke` | Skip `Invoke-SmokeValidate` even when the adapter module is loaded |
| `-FailFast` / `-Quiet` | Forwarded to `validate-core` when core runs |

1. Runs `scripts/validation/validate-core.ps1` by default. Skips that script only with `-SkipCore`. A non-zero core exit is the script exit.
2. After core passes (or is skipped), loads the adapter and calls `Invoke-SmokeValidate` when `InstallRoot` is available. Stub adapters (`Implemented = false`) are a documented no-op; when core ran, the core result still drives the exit code.

## Examples

```powershell
# Fixture sync (safe)
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent cursor
pwsh -NoProfile -File .\scripts\validate-agent.ps1 -Agent cursor

# Live Cursor
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent cursor -InstallRoot "$env:USERPROFILE\.cursor" -AllowUserHome

# Copilot both modes (fixtures). -Mode user|repo is required for copilot.
$u = Join-Path $PWD 'scripts\validation\fixtures\copilot\user'
$r = Join-Path $PWD 'scripts\validation\fixtures\copilot\repo'
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent copilot -Mode user -InstallRoot $u
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent copilot -Mode repo -InstallRoot $r

# Codex live home. -AllowUserHome is required under the user profile.
# -UserScope is optional and mirrors skills to ~/.agents/skills.
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent codex -InstallRoot "$env:USERPROFILE\.codex" -AllowUserHome
pwsh -NoProfile -File .\scripts\sync-agent.ps1 -Agent codex -InstallRoot "$env:USERPROFILE\.codex" -AllowUserHome -UserScope
```

## Related

- [INSTALL.md](../INSTALL.md)
- [VALIDATION.md](../VALIDATION.md)
- [ADAPTERS.md](../ADAPTERS.md)
