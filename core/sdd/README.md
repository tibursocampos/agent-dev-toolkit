# Core SDD contracts

The source of the SDD contracts is `core/skills/_shared/sdd-artifacts/`, which the toolkit's skills consume. `core/sdd/` holds byte-identical mirrors of the five contract files, kept for compatibility (`ToolkitConstants` references `core/sdd/SESSION.md` and `core/sdd/STORAGE-RESOLUTION.md`); each mirror must match its source. Each `Publish-Skills` implementation copies `core/skills/` (including `_shared/`) to its adapter's skills root and resolves path placeholders in the published copy. `Get-SddRoot -Prepare` is separate: it prepares `<InstallRoot>/sdd/sessions/` and seeds `<InstallRoot>/sdd/manifest.json` only when absent. It does not publish Markdown.

## Public constants

| Constant | Value | Notes |
|----------|-------|-------|
| `ManifestFileName` | `manifest.json` | Public SDD state file name. `schema_version` is numeric data, currently `2`, not a versioned filename. |
| `SddContractsRoot` | `core/sdd/` | Repo-relative compatibility mirror; the source is `core/skills/_shared/sdd-artifacts/`. |
| `ContractFiles` | `PIPELINE.md`, `STORAGE.md`, `SESSION.md`, `MEMORY-BANK.md` | Required contract set. |

## Source, projection, and consumers

For every row, the source is `core/skills/_shared/sdd-artifacts/<file>`, and the `core/sdd/<file>` mirror must be byte-identical to it. The consumer column names repository files that explicitly load or implement that contract; documentation mirrors are identified separately from runtime consumers. `Publish-Skills` distributes the checked-in projection in the following documented layouts. Paths below are relative to `InstallRoot` unless a live user root is named.

| Adapter / mode | Published shared-contract path | Applicability and evidence |
|----------------|--------------------------------|---------------------------|
| Cursor | `skills/_shared/sdd-artifacts/` | All syncs; `docs/ADAPTERS.md` Cursor publish layout. |
| Antigravity | `config/skills/_shared/sdd-artifacts/` | Official `config/*` layout; legacy `antigravity-ide/plugins` bridge is not a default publisher destination. |
| Copilot `user` and `repo` | `skills/_shared/sdd-artifacts/` | Same relative layout under either mode's `InstallRoot`. |
| Claude | `skills/_shared/sdd-artifacts/` | All syncs. |
| Codex default | `plugin/skills/_shared/sdd-artifacts/` | Plugin bundle. Also publishes `$` discovery mirror at `skills/_shared/sdd-artifacts/`. |
| Codex `-UserScope` | `.agents/skills/_shared/sdd-artifacts/` in fixture; `$HOME/.agents/skills/_shared/sdd-artifacts/` for live user scope | Optional mirror; live user scope requires `-AllowUserHome`. |
| OpenCode | `skills/_shared/sdd-artifacts/` | All syncs. |
| ZCode | `skills/_shared/sdd-artifacts/` | All syncs. |
| Grok | `skills/_shared/sdd-artifacts/` | All syncs. |
| Hermes | `skills/_shared/sdd-artifacts/` | All syncs. |
| OpenHands project | `.agents/skills/_shared/sdd-artifacts/` | Live `~/.agents` scope uses `skills/_shared/sdd-artifacts/` without the nested `.agents`. |

These layouts are the real `Publish-Skills` outputs documented in `docs/ADAPTERS.md`; the destination root can vary with adapter and InstallRoot. The SDK / `Get-SddRoot` destination `<InstallRoot>/sdd/` is not one of these Markdown destinations.

## Projection rules and current comparison

Publisher substitutions apply only in copied output. `{{TOOLKIT_ROOT}}` resolves to the published toolkit root (which can be the plugin root, `.agents`, or InstallRoot according to adapter/layout); `{{SDD_ROOT}}` resolves to the effective SDD root; `{{GUARDRAILS_PATH}}` resolves to that adapter's published guardrails file. A substitution is allowed only where the exact placeholder occurs. All other text is expected to remain identical. `docs/ADAPTERS.md` documents the destination-specific rules; no whole-directory exception is allowed.

| Contract | Concrete consumers (repo files) | Source-to-projection result | Exact projection rule or current drift |
|----------|-----------------|-----------------------------|---------------------------------------|
| `PIPELINE.md` | Runtime skills: `core/skills/sdd-spec/SKILL.md`, `sdd-plan/SKILL.md`, `sdd-develop/SKILL.md`, `orchestrate-analyze/SKILL.md`, `orchestrate-deliver/SKILL.md`, `orchestrate-develop/SKILL.md`. Shared policy summary: `core/policy/sdd-pipeline-guards.md`; router summary/pointer: `core/router/AGENTS.md`. | Byte-identical (checked by `SddContractMirrorIdentity`) | Current diff changes “one PLAN step per child” to “per child/invocation” and revises O3 close order and security review wording. These are content differences, not publisher transforms; resolve the source/projection drift before claiming parity. Header `{{TOOLKIT_ROOT}}` is a destination path placeholder only. |
| `STORAGE.md` | Runtime skills: `core/skills/sdd-spec/SKILL.md`, `sdd-plan/SKILL.md`, `sdd-develop/SKILL.md`, `orchestrate-analyze/SKILL.md`, `orchestrate-deliver/SKILL.md`, `orchestrate-develop/SKILL.md`, `memory-bank-init/SKILL.md`, `document-implement/SKILL.md`, and `document-plan/SKILL.md`. Router pointer: `core/router/AGENTS.md`. | Equal in checked-in pair | In published output, `{{TOOLKIT_ROOT}}` in the install-path header and `{{SDD_ROOT}}` in global-root references resolve to their effective roots. No other field may change. |
| `SESSION.md` | Runtime skills: `core/skills/sdd-spec/SKILL.md`, `sdd-plan/SKILL.md`, `sdd-develop/SKILL.md`, `orchestrate-analyze/SKILL.md`, `orchestrate-deliver/SKILL.md`, `orchestrate-develop/SKILL.md`, `memory-bank-init/SKILL.md`, and `document-implement/SKILL.md`. Gate/claim implementations: `scripts/session/Invoke-DevelopSessionGate.ps1`, `scripts/validation/validate-session-gates.ps1`, `scripts/validation/Assert-DevelopSessionGate.ps1`, and `scripts/ledger/Invoke-PlanLedgerClaim.ps1`. Router enforcement pointer: `core/router/AGENTS.md`. | Byte-identical (checked by `SddContractMirrorIdentity`) | Projection omits the complete “Persisted identity is a precondition to mutation (REQ-005 / CA5)” section present in the source and shortens the helper role row. These are content differences, not publisher transforms. Both persisted schemas in the source require `repo`; the PLAN-scoped schema also requires `plan_path`. Validators must check both identity fields; hashes alone are insufficient. `{{TOOLKIT_ROOT}}` in script references and `{{SDD_ROOT}}` in state paths are publish-time substitutions only. |
| `MEMORY-BANK.md` | Runtime skills: `core/skills/orchestrate-analyze/SKILL.md`, `orchestrate-deliver/SKILL.md`, `orchestrate-develop/SKILL.md`, and `memory-bank-init/SKILL.md` (Step 0 / Step N policy). Inventory operation: `scripts/inventory/Invoke-MemoryBankInventory.ps1`. Router pointer: `core/router/AGENTS.md`. | Byte-identical (checked by `SddContractMirrorIdentity`) | The checked-in projection changes the source command `.\scripts\inventory\Invoke-MemoryBankInventory.ps1` to the checked-in command `pwsh -NoProfile -File "{{TOOLKIT_ROOT}}/scripts/inventory/Invoke-MemoryBankInventory.ps1"`; this source-to-projection command-field transform makes invocation independent of the current directory. `Publish-Skills` only resolves `{{TOOLKIT_ROOT}}` in copied output. Header `{{TOOLKIT_ROOT}}` is also a destination path placeholder. Other text must be equal. |

The only approved structural substitutions are these named path placeholders in published skill content, plus the single `MEMORY-BANK.md` command projection above. Current PIPELINE/SESSION prose differences and any other changed fields are drift until corrected or specifically documented.

## State preparation boundary

`scripts/sync-agent.ps1` calls `Publish-*` and then `Get-SddRoot -Prepare`. The latter invokes `Initialize-SddRootLayout` to create `sdd/sessions/` and seed `sdd/manifest.json`; it does not copy the four contract Markdown files. Do not count those state files as contract destinations or attribute Markdown publishing to `Initialize-SddRootLayout`.

## Contract roles

| File | Role |
|------|------|
| `PIPELINE.md` | Spec / plan / develop order, canonical paths, confirmation gates |
| `STORAGE.md` | Feature tree, `.gitignore`, portable paths, navigation |
| `STORAGE-RESOLUTION.md` | Manifest, preferences, and dynamic storage roots |
| `SESSION.md` | Repo vs develop session files, required persisted identity, and gates |
| `MEMORY-BANK.md` | Step 0 / Step N policy, inventory operation, and router pointer (details in the contract-consumer inventory above). |
