# Memory Bank Gate (Forma C Step 0)

Single source of truth for the **workspace-scoped** `memory-bank/` contract and Step 0 / Step N policies used by `orchestrate-analyze`, `orchestrate-deliver`, and `orchestrate-develop`. Load on demand - do not paste into PRD/PLAN bodies.

Install path after sync: `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/cursor-install-root/skills/_shared/sdd-artifacts/MEMORY-BANK.md`

Companion skill: `memory-bank-init`. Inventory script: `scripts/inventory/Invoke-MemoryBankInventory.ps1`. Storage resolution: `STORAGE.md` (same manifest as `features/`).

**Language:** This guideline is **English**. Consumer bank prose may be pt-BR or English (ask once on create if ambiguous). Paths and identifiers stay English.

---

## Scope vs CONTINUITY

| Artifact | Scope | Role |
|----------|-------|------|
| `memory-bank/` | **Workspace** (cross-feature; co-located with `features/` via manifest) | Durable map: stack, architecture, domain, conventions, risks |
| `CONTINUITY.md` | **Feature** under `features/NNN-slug/` | Phase, `needs_*`, decisions, typed handoff; **reference** bank path/status only |

**Must not:** place `memory-bank/` under `features/NNN-slug/`. CONTINUITY must not duplicate bank body.

**Forma A (Classic SDD):** memory-bank is **optional** - not required for `sdd-spec` / `sdd-plan` / `sdd-develop`.

---

## Path resolution (manifest)

Resolve `$Cwd` as the target application/service workspace (not this toolkit repo unless that repo is the subject). Load `STORAGE.md` with `$Workflow = classic`, then:

| `storage_mode` | Bank root (`bank_root`) |
|----------------|-------------------------|
| **repository** | `$Cwd/memory-bank/` |
| **global** | `<classic.path>/memory-bank/` |

`features/` and `memory-bank/` share the same storage root. Never invent a bank path outside that root or under `features/NNN-slug/`.

---

## MVP contract tree

```text
memory-bank/
  project-context.md
  tech-stack.json
  architecture.md
  domain-knowledge.md
  conventions.md
  known-risks.md
  .inventory/
    sources.json
    gaps.md
    refresh-history.jsonl
```

| File | Purpose |
|------|---------|
| `project-context.md` | Product purpose, actors, boundaries (short) |
| `tech-stack.json` | Detected languages, frameworks, package managers, test runners |
| `architecture.md` | Layers, entry points, key modules |
| `domain-knowledge.md` | Bounded contexts / domain terms (evidence-based) |
| `conventions.md` | Repo conventions agents must follow |
| `known-risks.md` | Known footguns, fragile areas |
| `.inventory/sources.json` | Read-only evidence index (paths + mtimes) |
| `.inventory/gaps.md` | Missing / uncertain areas (incl. phase-2 stubs) |
| `.inventory/refresh-history.jsonl` | Append-only refresh log |

**Out of MVP (phase 2 / gaps only):** `api-contracts`, `database-schema`, `component-catalog` - list in `gaps.md` when detected as relevant, do not require files.

Templates: `skills/_shared/templates/memory-bank/` in this toolkit.

---

## Gate policies (Step 0)

| Policy | Behavior |
|--------|----------|
| `auto` (default for `orchestrate-*`) | Missing -> create; incomplete/stale -> refresh; healthy -> continue without write |
| `require` | **STOP** if missing/stale; handoff to `/memory-bank-init` (no auto-create) |
| `skip` | Bypass gate **only** when user passes an explicit flag (e.g. `skip-memory-bank` / documented invoke arg). Silence ≠ skip |

### Healthy bank

All MVP files present (except empty `refresh-history.jsonl` is OK) **and** not stale **and** no **blocking** gaps flagged in `gaps.md` (see Blocking gaps).

### Stale (MVP heuristics)

Mark **stale** if any of:

1. **Lockfile / stack evidence newer than inventory** - any of these exist and `LastWriteTimeUtc` > `sources.json` `generated_at` (or file mtime of `sources.json`): `package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `bun.lockb`, `Directory.Packages.props`, `packages.lock.json`, `*.sln` (newest), `Cargo.lock`, `poetry.lock`, `uv.lock`, `go.sum`, `Gemfile.lock`, `composer.lock`.
2. **Blocking gaps** - `gaps.md` contains a line starting with `- [ ] BLOCKING:` (unchecked).
3. **Age** - `sources.json` `generated_at` older than **stale_days** (default **90**). Override via skill arg or future preferences; do not invent other thresholds mid-session.

If `sources.json` missing but markdown files exist -> treat as **incomplete** (refresh).

### Blocking gaps

Agents may write non-blocking notes as `- [ ] …`. Only `- [ ] BLOCKING: …` forces stale/incomplete until checked off or removed after human ack.

**Inventory merge:** `Invoke-MemoryBankInventory.ps1` regenerates MVP/phase-2 stubs in `gaps.md` but **preserves** any existing line containing `BLOCKING:` (does not wipe human gate flags on refresh).

---

## Create / refresh rules

1. **Confirm before write** (pt-BR): show path + create|refresh|refresh-light; wait for **sim** / **ajustar** / **cancelar**. Healthy read-only path needs no confirm.
2. **No application code** - never create/edit `*.cs`, `*.ts`, app sources, migrations, etc. Bank + `.inventory/` only.
3. **No Spec Kit / uv / specify** - inventory is PowerShell (or agent Glob/Grep); no Python toolchain required on the consumer.
4. **Secrets** - never write API keys, tokens, connection strings, passwords, PII. Use env var **names** or `***`.
5. **Generated regions** - prefer markers so refresh replaces only machine sections:

```markdown
<!-- BEGIN GENERATED: inventory-summary -->
…
<!-- END GENERATED: inventory-summary -->
```

Human prose outside markers is preserved on refresh when practical.
6. **Selective read** - orchestrator parents load bank selectively (context-management); never dump entire bank into the parent prompt.

### Modes (`memory-bank-init`)

| Mode | When | Action |
|------|------|--------|
| `create` | Bank missing / incomplete scaffold | Templates + inventory + fill GENERATED |
| `refresh` | Stale / user asked full refresh | Inventory + update GENERATED + `tech-stack.json`; preserve human prose |
| `refresh-light` | O3 Step N after code changed; optional manual | Inventory + update GENERATED + `tech-stack.json` only; no full prose rewrite; append `refresh-history.jsonl` with `action: refresh-light` |

---

## Versioning (commit bank when product knowledge; never commit secrets)

| `storage_mode` | Bank on disk | Consumer `.gitignore` |
|----------------|--------------|------------------------|
| **repository** | `$Cwd/memory-bank/` | **Do not** add or require `/memory-bank/` in the SDD block (`STORAGE.md`). Commit bank when product knowledge; never commit secrets. |
| **global** | `<classic.path>/memory-bank/` | **Do not** edit project `.gitignore` (bank is outside the consumer git tree) |

Memory-bank holds durable product knowledge when useful — **commit bank when product knowledge; never commit secrets** (no keys, tokens, connection strings, raw `.env`). Do **not** treat `/memory-bank/` as a required SDD gitignore entry.

Toolkit itself may keep templates only - not a live bank unless documenting the toolkit as subject.

---

## Step 0 algorithm (orchestrate-* start)

```
1. Resolve bank_root via STORAGE.md (manifest classic -> repository | global)
2. Policy = auto (unless require/skip from user)
3. If skip (explicit): log and continue
4. Evaluate presence + completeness + stale at bank_root
5. auto + healthy -> read selective paths; status fresh; continue
6. auto + missing/incomplete/stale -> confirm -> run memory-bank-init (create|refresh) -> continue
7. require + not healthy -> STOP + handoff /memory-bank-init
8. Record status for CONTINUITY: fresh | refreshed | created
```

**Wiring:** O1, O2, and O3 (`orchestrate-*`) implement Step 0. Forma A (`sdd-*`) does not require the gate.

---

## Step N algorithm (O3 end - refresh-light)

After O3 has changed application code (at least one develop child succeeded with file changes):

```
1. Resolve bank_root (same as Step 0)
2. Confirm (pt-BR) refresh-light at bank_root
3. Run memory-bank-init mode refresh-light (inventory + GENERATED + tech-stack.json)
4. Record CONTINUITY Memory-bank status refreshed (or note skipped if cancelar)
```

| Phase | Step N? |
|-------|---------|
| **O3** (`orchestrate-develop`) | **Yes** when code changed this run |
| **O1** | Optional point promote only (architecture/domain/risk fact) - not full inventory by default |
| **O2** | **No** end refresh (O2 does not change app code) |

Do **not** full-refresh at every O1/O2 start “just in case” - Step 0 already handles stale.

---

## Inventory script

```powershell
.\scripts\inventory\Invoke-MemoryBankInventory.ps1 -RepoPath "<consumer>" -BankPath "<bank_root>" -AllowCreateInventory
```

- **Read-only** over consumer source tree (`-RepoPath` = `$Cwd`).
- **Writes only** under `<bank_root>/.inventory/` (`-BankPath` may be `$Cwd/memory-bank` or `<classic.path>/memory-bank`).
- Output: `sources.json`, updates `gaps.md` stubs when stack signals rich contracts, appends `refresh-history.jsonl`.

---

## Handoff strings

```text
/memory-bank-init
/memory-bank-init - refresh
/memory-bank-init - refresh-light
/orchestrate-analyze
```
