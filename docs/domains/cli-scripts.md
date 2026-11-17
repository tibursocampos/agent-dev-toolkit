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
| `scripts/validation/Invoke-AdapterCiSmoke.ps1` | CI-parity smoke for one registry adapter |
| `scripts/validation/Assert-AdapterPublish.ps1` | Adapter static checks plus one real publish (`-Adapter <id>`, `-All`); work under `.adt-work/` |
| `scripts/inventory/Invoke-MemoryBankInventory.ps1` | Read-only bank inventory (`ready` \| `not-ready`) |
| `scripts/trace/Invoke-TraceHarvest.ps1` | Feature-scoped TRACE harvest |
| `scripts/trace/Invoke-AuthorshipGitNotes.ps1` | Opt-in authorship git-notes (default off; never TRACE SoT) — [guide 09](../guides/09-authorship-git-notes.md) |
| `scripts/session/Invoke-DevelopSessionGate.ps1` | Session helper for `adt-document-implement` |
| `scripts/validation/Invoke-SiblingReadinessGate.ps1` | Selective clarify READY / NEEDS_CLARIFICATION (WS3) |
| `scripts/_lib/Test-ToolkitFileReadback.ps1` | Shared write-then-readback helper for `adt-document-implement` session persistence |

Shared helpers: `scripts/_lib/` (`Resolve-InstallRoot`, `Resolve-RegistryAgent`, toolkit constants, …).

## Skill reference inventory and publication policy

Every executable script path referenced from `core/skills/**/*.md` is classified below. Runtime entries are published by `scripts/sync-agent.ps1` from `scripts/runtime/runtime-manifest.json` under each resolved `TOOLKIT_ROOT/scripts/`. The primary root is `<InstallRoot>`; Codex also publishes to `<InstallRoot>/plugin` and, with `-UserScope`, `<InstallRoot>/.agents`; OpenHands project installs also publish to `<InstallRoot>/.agents` (a user install whose root is already `.agents` uses the primary root only). `support` files are copied only as transitive dependencies of the listed runtime entries. No folder-wide `scripts/` copy occurs.

| Source | Caller / reference | Class | Installed destination |
|--------|--------------------|-------|-----------------------|
| `scripts/inventory/Invoke-MemoryBankInventory.ps1` | `adt-memory-bank`, shared MEMORY-BANK contract | runtime | matching `TOOLKIT_ROOT/scripts/inventory/` path |
| `scripts/session/Invoke-DevelopSessionGate.ps1` | `adt-document-implement` session contract | runtime | matching `TOOLKIT_ROOT/scripts/session/` path |
| `scripts/validation/Invoke-SiblingReadinessGate.ps1` | shared readiness-severity contract | runtime | matching `TOOLKIT_ROOT/scripts/validation/` path |
| `scripts/validation/validate-session-gates.ps1` | shared SESSION contract | runtime | matching `TOOLKIT_ROOT/scripts/validation/` path |
| `scripts/validation/validate-evidence.ps1`, `validate-trace.ps1` | `adt-sdd-develop` evidence/archive gates | runtime | matching `TOOLKIT_ROOT/scripts/validation/` paths |
| `scripts/validation/validate-prd.ps1`, `validate-plan.ps1`, `validate-change.ps1` | Optional structural diagnostics when explicitly requested; not flow authorization gates | runtime | matching `TOOLKIT_ROOT/scripts/validation/` paths |
| `scripts/_lib/ToolkitConstants.ps1`, `Get-ToolkitRepoRoot.ps1`, `Resolve-EffectiveSddRoot.ps1`, `Resolve-InstallRoot.ps1`, `Test-ToolkitFileReadback.ps1` | dot-sourced by published runtime scripts that require them | support | matching `TOOLKIT_ROOT/scripts/_lib/` paths (manifest-listed files only) |
| `scripts/validation/Assert-*.ps1` (including `Assert-CoreContracts`, `Assert-AdapterContract`, `Assert-RuntimeCopyDrift`, `Assert-O3ReceiptValidation`, `Assert-DevelopSessionGate`), `scripts/validation/validate-core.ps1` (in-process runner with `-Only` / `-Skip`), `scripts/validation/Invoke-AdapterCiSmoke.ps1 -Adapter <id>` | contract and CI validation of toolkit sources; none reads a `features/` tree | internal | not published |
| `scripts/validation/fixtures/**`, `scripts/validation/contracts/**` | validator fixtures and toolkit contract data; self-test scratch roots live under `<repo>/.adt-work/` (git-ignored) or the system temp folder | internal | not published |
| `scripts/sync-agent.ps1`, `scripts/toolkit.ps1`, bootstrap, uninstall/publish scripts, remaining `scripts/_lib/**` | toolkit installation and maintenance instructions | internal | not published |

Runtime scripts must receive explicit `{{TOOLKIT_ROOT}}/scripts/...` references in skills. The inventory script requires `-RepoPath`; it does not search for or depend on an open toolkit checkout. Sync fails with the source path and calling skill when a manifest entry is missing.

## Session helper

`Invoke-DevelopSessionGate.ps1` remains available to `adt-document-implement`, whose contract explicitly uses session state. Classic SDD and O1/O2/O3 do not use session flags or claims as execution prerequisites. When the helper's consumer calls it, use `-File` and retain the host's ordinary explicit Shell authorization:

`scripts/session/Invoke-DevelopSessionGate.ps1`

For published runtime use, `-SddRoot` defaults to the active InstallRoot's `sdd` directory. A deliberate caller or isolated test may pass a different root. The helper does not infer a root from the user profile. Do not auto-approve all Shell or mutate hooks policy silently. Cursor detail: [adapters/cursor/README.md](../../adapters/cursor/README.md) § Session helper.

## Optional operator helpers

These scripts are independent utilities, not a required sequence or approval pipeline. Classic and Orchestrated Delivery follow their skill contracts and canonical PLAN.

| Utility | Use |
|---------|-----|
| `Invoke-MemoryBankInventory.ps1` | Explicitly requested inventory of an existing or authorized memory bank |
| `Invoke-SiblingReadinessGate.ps1` | Optional readiness diagnostic for consumers that request it |
| `Invoke-TraceHarvest.ps1` | Explicit summary of `features/NNN-slug/TRACE.jsonl` |

Contracts (do not paste full schema here): [TRACE archive](core.md#trace-archive-living-loop), [readiness](core.md#clarification-readiness-b--i--minor), [VALIDATION.md](../VALIDATION.md).

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

Evaluates open clarification markers (B / I / MINOR) per `readiness-severity.md` under that feature/story root. Open **B**, **I**, or **MINOR** → exit `NEEDS_CLARIFICATION` (blocks O2 / refine handoff as READY). Presence of sibling folders alone is not READY. Domain: [core readiness](core.md#clarification-readiness-b--i--minor).

### TRACE harvest

```powershell
pwsh -NoProfile -File .\scripts\trace\Invoke-TraceHarvest.ps1 `
  -FeatureRoot features\<NNN-slug>
```

Summarizes events from that feature’s `TRACE.jsonl` only (includes `tokens` / `duration` / `spawn` when present). Path escape or sessions-root reads fail explicitly — never dumps `sdd/sessions`.

### Session helper (`adt-document-implement`)

```powershell
pwsh -NoProfile -File .\scripts\session\Invoke-DevelopSessionGate.ps1 `
  -PlanPath docs\documentation-plan\plan.md -RepoPath . -SddRoot <sdd-root>
```

This example is for the `adt-document-implement` consumer. For published runtime helpers, `-SddRoot` is optional and defaults to the active InstallRoot's `sdd` directory. Pass it explicitly when running from source or selecting a test root.

Assert: `Assert-DevelopSessionGate.ps1`.

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
