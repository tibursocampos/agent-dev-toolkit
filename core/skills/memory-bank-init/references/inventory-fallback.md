## Inventory script resolution (prefer before fallback)

Resolve `Invoke-MemoryBankInventory.ps1` in this order — **do not** Glob only under the host skills install root / agent home (sync does **not** publish `scripts/`):

1. `{{TOOLKIT_ROOT}}/scripts/inventory/Invoke-MemoryBankInventory.ps1` (or agent-dev-toolkit clone / `AGENTS.md` toolkit root)
2. Relative from toolkit repo when `$Cwd` **is** the toolkit: `./scripts/inventory/Invoke-MemoryBankInventory.ps1`
3. Optional synced copy under the install root **if present**
4. Only then this fallback

When the script is found (create / refresh / refresh-light):

```powershell
.\scripts\inventory\Invoke-MemoryBankInventory.ps1 -RepoPath "<consumer>" -BankPath "<bank_root>" -AllowCreateInventory -Action refresh
```

Use `-Action refresh-light` for O3 Step N; default `inventory` for create-only scans. Exit `0` = `ready`; exit `2` = `not-ready` (read reason from `sources.json`).

---

## Manual inventory fallback (STRICT — script unreachable only)

**NEVER** recursive whole-repo inventory. Cap curated sources; `files` is **INVALID**.

### Allowlist (same curated set as script `Get-DefaultInventoryRelativePaths`)

Exists-only checks under `$Cwd` (reject `..` / path escape → `not-ready`):

| Kind | Relative paths / patterns |
|------|---------------------------|
| Root docs | `README.md`, `SECURITY.md`, `CONTRIBUTING.md`, `LICENSE`, `.gitignore`, `AGENTS.md`, `CLAUDE.md` |
| Lockfiles | `package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `bun.lockb`, `Directory.Packages.props`, `packages.lock.json`, `Cargo.lock`, `poetry.lock`, `uv.lock`, `go.sum`, `Gemfile.lock`, `composer.lock` |
| Manifests | `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `Gemfile`, `composer.json` |
| Toolkit-ish | `adapters/registry.json`; `scripts/toolkit.ps1`, `scripts/sync-agent.ps1`, `scripts/validate-agent.ps1`, `scripts/validation/validate-core.ps1`; `core/skills/_shared/agents/SPAWN.md`; `core/router/AGENTS.md` |
| Scoped globs (non-recursive except noted) | `*.sln` under repo root; `scripts/_lib/*.ps1`; `docs/**/*.md`; `.github/workflows/*.yml`; `adapters/*Adapter.ps1`, `adapters/Publish-*.ps1`, `adapters/Uninstall-*.ps1` |

Do **not** invent additional trees (`src/**`, `node_modules/**`, etc.).

### Wire format (schema_version **3** only)

Write `sources.json` as:

- Top-level: `schema_version: 3`, `repo`, `repo_path`, `bank_path`, `generated_at`, `stale_days`, `status` (`ready` \| `not-ready`), `status_reason`, `inventory_hash` (SHA256 over sorted `path:hash` lines), `inventory_summary` (`N source(s); stack: …`), `stack_hints`, `sources` (array)
- **`repo_path` / `bank_path` MUST be portable** — `repo_path` = `.`; `bank_path` = repo-relative forward-slash path (usually `memory-bank`). **Never** OS absolute / drive-letter / user-home machine paths (file is versioned under `memory-bank/`).
- Each `sources[]` entry: `path` (repo-relative, forward slashes), `last_write_utc`, `length`, `hash` (SHA256 hex), `summary` (first heading or first non-empty line; redact secret-named files)
- **`files` key is INVALID** — never write it. If an existing file has `files` and no usable `sources`, migrate those paths into `sources` once, then rewrite v3 without `files`.

### Cap / bloated reset

- Soft cap: **200** source paths.
- If existing `sources.json` has **> 200** paths (or looks like a full-tree dump): **RESET** to curated allowlist discovery only; set `status_reason` to note `bloated_reset: existing source count exceeded 200; reset to curated discovery` (still `ready` when curated index succeeds).
- When existing count ≤ 200 and uses `sources`: re-hash those paths **plus** curated discovery (do not follow `..`).

### Other writes

1. `gaps.md` — MVP checklist + phase-2 hints; preserve any line containing `BLOCKING:`.
2. Append `refresh-history.jsonl`.
3. Surface `status` / `status_reason` / `inventory_hash` / `inventory_summary` in the skill report.

Still **write only** under `<bank_root>/.inventory/` (resolved via `STORAGE.md`).
