# Optional workspace Memory Bank

Reference for the **workspace-scoped** `memory-bank/` format and explicit `adt-memory-bank` operations. Classic SDD and Orchestrated Delivery may consult an existing bank when relevant, but do not require creation, inventory, refresh, or Step 0/Step N as a condition of analysis, planning, implementation, or closeout. Load on demand - do not paste into PRD/PLAN bodies.

Install path after sync: `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/MEMORY-BANK.md`

Companion skill: `adt-memory-bank`. Inventory script: `scripts/inventory/Invoke-MemoryBankInventory.ps1` — resolve via toolkit root / clone (see Inventory below); sync does **not** publish `scripts/` into the host skills install root. Storage resolution: `STORAGE.md` + `STORAGE-RESOLUTION.md` (same manifest as `features/`; load the latter when resolving `bank_root`).

**Credits:** durable-bank ideas are inspired in part by practices around [github/spec-kit](https://github.com/github/spec-kit); this toolkit does **not** run Spec Kit / uv / specify. See `docs/CREDITS.md`.

**Language:** This guideline is **English**. Consumer bank prose follows project convention / content-language (`LANGUAGE.md`); ask once on create only when no evidence of project doc language. Paths and identifiers stay English.

---

## Scope vs CONTINUITY

| Artifact | Scope | Role |
|----------|-------|------|
| `memory-bank/` | **Workspace** (cross-feature; co-located with `features/` via manifest) | Durable map: stack, architecture, domain, conventions, risks |
| `CONTINUITY.md` | **Feature** under `features/NNN-slug/` | Phase, `needs_*`, decisions, typed handoff; **reference** bank path/status only |

**Must not:** place `memory-bank/` under `features/NNN-slug/`. CONTINUITY must not duplicate bank body.

**Classic SDD and Orchestrated Delivery:** memory-bank is optional. Existing content may be read when relevant. Do not auto-create, refresh, or promote content into the bank as an O1/O2/O3 gate. Phase 2 files and refresh operations apply only when the operator explicitly requests a bank operation or another unchanged consumer requires them.

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

Templates: `skills/_shared/templates/memory-bank/` in this toolkit.

### Phase 2 files (rich contracts)

| File | When **BLOCKING** (or promote immediately) |
|------|--------------------------------------------|
| `database-schema.md` | Prior / cited content already has DDL or SQL |
| `api-contracts.md` | Prior / cited content already has OpenAPI / Swagger |
| `component-catalog.md` | Prior / cited content already has a UI component map |

If that body already exists in Prior or a cited `.md`, the matching phase 2 file is **BLOCKING**: write or promote it immediately, or flag `- [ ] BLOCKING:` in `gaps.md` until written. Empty `gaps.md` phase 2 stubs in that case are **not** “optional forever”.

When those signals are **absent**, list the topic in `gaps.md` only — do not require the file.

---

## Retired orchestration gate policy (reference only)

| Policy | Behavior |
|--------|----------|
| Classic / Orchestrated Delivery | No Step 0 auto/require/skip gate; optionally read relevant existing files. |
| Explicit `adt-memory-bank` | Use the selected operation and its own authorization; the skill remains directly invocable. |

### Healthy bank

All MVP files present (except empty `refresh-history.jsonl` is OK) **and** not stale **and** no **blocking** gaps flagged in `gaps.md` (see Blocking gaps).

### Stale (MVP heuristics)

Mark **stale** if any of:

1. **Lockfile / stack evidence newer than inventory** - any of these exist and `LastWriteTimeUtc` > `sources.json` `generated_at` (or file mtime of `sources.json`): `package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `bun.lockb`, `Directory.Packages.props`, `packages.lock.json`, `*.sln` (newest), `Cargo.lock`, `poetry.lock`, `uv.lock`, `go.sum`, `Gemfile.lock`, `composer.lock`.
2. **Blocking gaps** - `gaps.md` contains a line starting with `- [ ] BLOCKING:` (unchecked).
3. **Age** - `sources.json` `generated_at` older than **stale_days** (default **90**). Override via skill arg or future preferences; do not invent other thresholds mid-session.

If `sources.json` missing but markdown files exist -> treat as **incomplete** (refresh).

### Blocking gaps

Agents may write non-blocking notes as `- [ ] …`. Only `- [ ] BLOCKING: …` forces stale/incomplete until checked off or removed after human ack. Phase 2 files that are BLOCKING (Prior/cited already has DDL, OpenAPI, or a UI component map) must use this flag until the file is written/promoted.

**Inventory merge (agent-enforced):** On create/refresh/refresh-light, regenerate MVP/phase-2 stubs in `gaps.md` but **preserve** any existing line containing `BLOCKING:` — agents must not wipe human gate flags even when `Invoke-MemoryBankInventory.ps1` is absent (use Glob/Grep per `adt-memory-bank/reference.md`).

---

## Explicit create / refresh rules

1. **Confirm before write** (user chat language): show path + create|refresh|refresh-light; wait for **sim** / **ajustar** / **cancelar** (or session-equivalent). Healthy read-only path needs no confirm.
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
6. **Selective read** - orchestrator parents load only the bank files needed for the current decision; never dump the entire bank into the parent prompt. Normative rule: `SELECTIVE-RETRIEVAL.md`; smoke: `Assert-CoreContracts.ps1` (SelectiveRetrieval section).
7. **Inventory → specialist synthesis** - after inventory, `adt-memory-bank` runs the signal→specialist flow in `skills/adt-memory-bank/references/inventory-specialist-synthesis.md`. Skip D: no tracker mutate, no external spec-tool constitution.

### Modes (`adt-memory-bank`)

| Mode | When | Action |
|------|------|--------|
| `create` | Bank missing / incomplete scaffold | Templates + inventory + **specialist synthesis** + fill GENERATED |
| `refresh` | Stale / user asked full refresh | Inventory + synthesis when signals warrant + update GENERATED + `tech-stack.json`; preserve human prose |
| `refresh-light` | Explicitly requested light refresh | Inventory + update GENERATED + `tech-stack.json` only; thin stack synthesis; no full prose rewrite; append `refresh-history.jsonl` with `action: refresh-light` |

---

## Versioning (commit bank when product knowledge; never commit secrets)

| `storage_mode` | Bank on disk | Consumer `.gitignore` |
|----------------|--------------|------------------------|
| **repository** | `$Cwd/memory-bank/` | **Do not** add or require `/memory-bank/` in the SDD block (`STORAGE.md`). Commit bank when product knowledge; never commit secrets. |
| **global** | `<classic.path>/memory-bank/` | **Do not** edit project `.gitignore` (bank is outside the consumer git tree) |

Memory-bank holds durable product knowledge when useful — **commit bank when product knowledge; never commit secrets** (no keys, tokens, connection strings, raw `.env`). Do **not** treat `/memory-bank/` as a required SDD gitignore entry.

Toolkit itself may keep templates only - not a live bank unless documenting the toolkit as subject.

---

## Legacy Step 0 algorithm (not used by Classic or Orchestrated Delivery)

```
1. Resolve bank_root via `STORAGE.md` + `STORAGE-RESOLUTION.md` (manifest classic -> repository | global). Load the resolution guide for the manifest-backed root algorithm.
2. Policy = auto (unless require/skip from user)
3. If skip (explicit): log and continue
4. Evaluate presence + completeness + stale at bank_root
5. auto + healthy -> read selective paths; status fresh; continue
6. auto + missing/incomplete/stale -> confirm -> run adt-memory-bank (create|refresh) -> continue
7. require + not healthy -> STOP + handoff /adt-memory-bank
8. Record status for CONTINUITY: fresh | refreshed | created
```

**Wiring:** O1/O2/O3 do not implement Step 0. Classic SDD also does not require it.

---

## Legacy Step N algorithm (not used by O3)

After O3 has changed application code (at least one develop child succeeded with file changes):

```
1. Resolve bank_root (same as Step 0)
2. Confirm (user chat language) refresh-light at bank_root
3. Run adt-memory-bank mode refresh-light (inventory + GENERATED + tech-stack.json)
4. Record CONTINUITY Memory-bank status refreshed (or note skipped if cancelar)
```

| Phase | Step N? |
|-------|---------|
| **O3** (`adt-orchestrate-implement`) | No automatic refresh; use only when explicitly requested |
| **O1** | After ARCH **sim**: **point-promote** / update `memory-bank/architecture.md` so it is not left draft / `needs-confirm`. Optional point-promote of domain/risk facts. **Not** a full inventory refresh. |
| **O2** | **No** full inventory refresh (O2 does not change app code). If style changed or ARCH was approved this feature, do **not** exit with status `fresh` — set `refreshed` (point-promote `architecture.md` if not already). |

Do **not** full-refresh at every O1/O2 start “just in case” - Step 0 already handles stale. **Point-promote** of `architecture.md` after ARCH **sim** is the exception: a targeted file update, **not** a full inventory refresh.

---

## Inventory (script or agent fallback)

**Script resolution order** (do **not** Glob only under the host skills install root):

1. `{{TOOLKIT_ROOT}}/scripts/inventory/Invoke-MemoryBankInventory.ps1` (or agent-dev-toolkit clone / `AGENTS.md` toolkit root)
2. Relative from toolkit repo when `$Cwd` is the toolkit
3. Optional synced copy under install root **if present**
4. Only then agent fallback (`adt-memory-bank/references/inventory-fallback.md`) — curated allowlist only; never full-repo recurse; wire is schema_version **3** + `sources` (`files` invalid)

Prefer toolkit script when resolved:

```powershell
pwsh -NoProfile -File "{{TOOLKIT_ROOT}}/scripts/inventory/Invoke-MemoryBankInventory.ps1" -RepoPath "<consumer>" -BankPath "<bank_root>" -AllowCreateInventory
```

Use `-Action refresh-light` only for an explicitly requested light refresh. Bloated existing index (> ~200 paths) resets to curated discovery, after drift is compared against the prior snapshot. A prior `sources.json` that is empty, `null`, or whose `sources` is not a non-empty array is not a baseline: the run is `not-ready` with reason `prior_snapshot_invalid`. A source path that is or passes through a reparse point (symlink or junction) is never read or hashed: the run is `not-ready` with reason `path_reparse_point`.
- **Read-only** over consumer source tree (`-RepoPath` = `$Cwd`).
- **Writes only** under `<bank_root>/.inventory/` (`-BankPath` may be `$Cwd/memory-bank` or `<classic.path>/memory-bank`).
- Output: `sources.json` (v3 + `sources[]`), updates `gaps.md` stubs when stack signals rich contracts, appends `refresh-history.jsonl`. Preserve `- [ ] BLOCKING:` lines in `gaps.md` on every refresh; the text after the prefix passes the same sensitive-content redaction as other human notes.
- **Portable roots (required):** `sources.json` top-level `repo_path` MUST be `.` and `bank_path` MUST be a repo-relative forward-slash path (usually `memory-bank`). **Never** write OS absolute / drive-letter / user-home machine paths — the file is versioned under `memory-bank/`. `refresh-history.jsonl` `repo` field uses the repo leaf name or `.`, never an absolute path.

---

## Handoff strings

```text
/adt-memory-bank
/adt-memory-bank - refresh
/adt-memory-bank - refresh-light
/adt-orchestrate-analyze
```

## adt-sdd-plan read

In `adt-sdd-plan`, an existing bank is read-only. An old or incomplete bank does not block. A missing bank asks permission once. Current code wins when it disagrees with the bank.
