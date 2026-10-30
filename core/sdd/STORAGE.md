# SDD artifact storage (sdd-spec / sdd-plan / sdd-develop)

Single source of truth for where Classic SDD and Orchestrated Delivery artifacts are written. Load on demand from skills - do not paste this file into PRD/PLAN bodies.

**Language:** This guideline file is **English**. SDD artifact prose (FEATURE, STORY, PRD, PLAN, CONTINUITY, …) follows **content-language** per `agents/LANGUAGE.md` (invocation → `preferences.artifact_language` → manifest → else chat language; `null` ≠ pt-BR). **Chat** replies and the storage prompt below mirror the **user chat language**. Identifiers / paths stay English.

Install path after sync: `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/STORAGE.md`

## Dynamic storage resolution

When the task must choose or resolve repository/global storage, read [`STORAGE-RESOLUTION.md`](./STORAGE-RESOLUTION.md). That reference owns the manifest, effective SDD root, preferences, and dynamic path algorithm. Load it just in time; artifact naming, portable paths, navigation, and feature-tree rules remain here.

## Storage modes

| Mode | Feature root | Memory-bank root |
|------|--------------|------------------|
| **repository** | `$Cwd/features/NNN-slug/` | `$Cwd/memory-bank/` |
| **global** | `<path>/features/NNN-slug/` where `<path>` = `{{SDD_ROOT}}/<repo-id>/` (or manifest `classic.path`) | `<path>/memory-bank/` |

Use `{{SDD_ROOT}}/...` on macOS/Linux when expanding paths in tools.

**Co-location:** `features/` and `memory-bank/` always share the same storage root (`$Cwd` or `<classic.path>`). Never place `memory-bank/` under `features/NNN-slug/`. Contract details: `MEMORY-BANK.md`.

**Read/resume behavior:** `storage_mode` and `classic.path` select the feature root. `features_versioned` controls Git tracking only; it does not select a different root or make ignored files unavailable. Resolve the exact canonical path by direct filesystem access, not `git ls-files` or a listing that excludes ignored files. In global mode, a same-named repository-local artifact is a decoy, and the consumer repository `.gitignore` is not modified.

**New writes (Classic SDD / preferred Backlog Refine / Orchestrated Delivery):** only under `features/NNN-slug/` (never loose `REFINE/`, `ANALYSIS/`, `ARCH/`, `SEC/`, `PRD/`, or `PLAN/` at repo root).

**No legacy root flow:** do **not** read, write, glob, or continue develop from repo-root / global-flat `PRD/` or `PLAN/`. Those patterns remain in `.gitignore` only as a safety net against accidental files.

## Feature tree schema

```text
features/NNN-slug/
├── FEATURE.md                 # Feature overview (Orchestrated Delivery / optional Classic SDD)
├── CONTINUITY.md              # Cross-agent / cross-session handoff
├── CHANGE.md                  # Brownfield delta vs current (ADDED|MODIFIED|REMOVED); required when Nature=brownfield — see CHANGE-CONTRACT.md
├── TRACE.jsonl                # Append-only event trail; living loop converge → sync_current → archive (P3); see TRACE-ARCHIVE-CONTRACT.md
└── USnn/ or TSnn/             # Story folder (nn = 01, 02, …)
    ├── STORY.md               # Refined story + scorecard / deps
    ├── REFINE/                # Refine / breakdown scratch (optional / on demand); tasks.md when complexity ≥ medium
    ├── ANALYSIS/              # Impact / risk notes (required when needs_api or brownfield)
    ├── ARCH/                  # Architecture notes (required when needs_domain, needs_database, or brownfield)
    ├── SEC/                   # Security notes (required when needs_security)
    ├── EVD/                   # Story-scoped post-implementation evidence (when level ≥ cheap)
    ├── STATE.md               # Story-scoped AC → evidence matrix
    ├── PRD/                   # Canonical PRD for this story
    │   └── NNN_short_slug.md
    └── PLAN/
        └── PLAN_NNN_short_slug.md
```

| Segment | Rule |
|---------|------|
| `NNN` | Three digits; shared across feature folder and PRD/PLAN filenames |
| `slug` | kebab-case feature id |
| `USnn` / `TSnn` | User story or technical story; zero-padded index |
| `CHANGE.md` | Feature-root brownfield delta vs **current** (`memory-bank/` living docs). Required when FEATURE Nature is `brownfield`. Greenfield must not force an empty stub. Contract: `CHANGE-CONTRACT.md`. |
| `EVD/` | Story-root evidence folder for post-implementation verify. Required when evidence level ≥ `cheap`. Contract: `EVD-STATE-CONTRACT.md`. Historical feature-root evidence is preserved and not bulk-migrated. |
| `STATE.md` | Story-root AC → evidence matrix + **Evidence level** (`off` \| `cheap` \| `standard` \| `strict`). Gate via `validate-evidence.ps1`. **Verifier ≠ O3**. |
| `TRACE.jsonl` | Feature-root append-only JSONL trail. Living loop **converge → sync current → archive** (REQ-006 / CA5). Gate via `validate-trace.ps1` (`-RequireArchiveComplete` at close). Contract: `TRACE-ARCHIVE-CONTRACT.md`. |
| Story subfolders | `REFINE/` optional / on demand (`tasks.md` when complexity ≥ medium). `ANALYSIS/` / `ARCH/` / `SEC/` required on disk when the matching FEATURE `needs_*` (or brownfield) is true. Never create the same names at **repo root**. `PRD/` / `PLAN/` are O2. |

**Classic SDD (no O1 backlog):** create `features/NNN-slug/US01/` (default story) and write PRD/PLAN there unless the user names another `USnn`/`TSnn`.

**Templates (scaffold only):** `skills/_shared/templates/features/` in this toolkit repo (includes `CHANGE.md`, `STATE.md`, `EVD/README.md`, `TRACE.jsonl`).  
**SDD PRD/PLAN document templates:** `skills/_shared/templates/sdd/PRD.md` and `skills/_shared/templates/sdd/PLAN.md` (authoring rules in `sdd-spec` / `sdd-plan` `reference.md`).
**CHANGE / current specs:** `skills/_shared/sdd-artifacts/CHANGE-CONTRACT.md`.  
**EVD / STATE / evidence-or-zero:** `skills/_shared/sdd-artifacts/EVD-STATE-CONTRACT.md`.  
**TRACE / archive / sync current:** `skills/_shared/sdd-artifacts/TRACE-ARCHIVE-CONTRACT.md`.

## Repository mode - `.gitignore`

Run **before** the first `Write` under any SDD folder or `memory-bank/` in the workspace (`sdd-spec`, `sdd-plan`, `orchestrate-*`, `memory-bank-init` in **repository** mode only).

1. Read `features_versioned` from `manifest.json` (`repositories[$Cwd].classic.features_versioned`, default `false`). Read `.gitignore` at workspace root. If missing, create it with the SDD block for the active mode.
2. **Always** require these patterns in repository mode (safety-net + documentation-plan exception):

   | Pattern | When used |
   |---------|-----------|
   | `/features/` | Ignore when `features_versioned` is `false`; **omit** when `true` |
   | `/docs/features/` | Same as `/features/` |
   | `/PRD/` | Safety net - ignore accidental root PRD (not a write destination) |
   | `/PLAN/` | Safety net - ignore accidental root PLAN (not a write destination) |
   | `/docs/PRD/` | Safety net |
   | `/docs/PLAN/` | Safety net |
   | `/docs/documentation-plan/*` | Ignore scratch under documentation-plan |
   | No negation pattern | `docs/documentation-plan/plan.md` remains ignored with the rest of the documentation-plan scratch files; do not add a negation rule |

   **Do not** add or require `/memory-bank/` in the SDD ignore block. Commit bank when product knowledge; never commit secrets.

   Use leading `/` so `skills/sdd-plan/`, `skills/_shared/templates/features/`, `skills/_shared/templates/memory-bank/`, and other non-root paths are **not** ignored.

3. If **any** required pattern for the active `features_versioned` mode is missing, append or migrate the **full** block below. **Remove** legacy `/docs/documentation-plan/` (whole folder) if present — replace it with `/docs/documentation-plan/*`, without a negation for `plan.md`. When `features_versioned` is `true`, **never** re-add `/features/` or `/docs/features/` even if absent from `.gitignore`.

   `features_versioned: false` (default):

   ```gitignore
   # SDD artifacts (local agent workflow - agent-dev-toolkit)
   /features/
   /docs/features/
   /PRD/
   /PLAN/
   /docs/PRD/
   /docs/PLAN/
   /docs/documentation-plan/*
   ```

   `features_versioned: true`:

   ```gitignore
   # SDD artifacts (local agent workflow - agent-dev-toolkit)
   /PRD/
   /PLAN/
   /docs/PRD/
   /docs/PLAN/
   /docs/documentation-plan/*
   ```

4. Report: patterns added, migrated, or all already present. If `/memory-bank/` is already present from an older policy, do **not** re-add it; the human may remove it so the bank can be versioned. If the human removed `/features/` manually and manifest has no `features_versioned` yet, ask once and persist the choice.


**Global mode:** do **not** modify project `.gitignore`. Do **not** add or require `/features/`, `/PRD/`, `/PLAN/`, or related patterns - those artifacts live under `<classic.path>/` outside the consumer git tree. Skills must not suggest appending the SDD block when `storage_mode` is `global`.

**Migration repository -> global:** skills do **not** auto-remove SDD lines from `.gitignore`; the human may delete the block if desired.

## Numbering (`NNN`)

Collect existing sequence numbers from **features** locations before assigning `NNN`:

| Location | Glob |
|----------|------|
| Workspace features | `features/*/`, `docs/features/*/` (folder names `NNN-slug`) |
| Global features | `<classic.path>/features/*/` |

Use the highest `NNN` across all matches, then +1. PLAN `NNN` **must match** its feature folder and source PRD sequence.

Do **not** scan repo-root `PRD/` / `PLAN/` or global-flat `PRD/` / `PLAN/` for numbering.

## Filenames

| Artifact | Pattern | Typical path |
|----------|---------|--------------|
| Feature overview | `FEATURE.md` | `features/NNN-slug/FEATURE.md` |
| Continuity | `CONTINUITY.md` | `features/NNN-slug/CONTINUITY.md` |
| Story | `STORY.md` | `features/NNN-slug/USnn/STORY.md` |
| PRD | `NNN_short_feature_slug.md` | `features/NNN-slug/USnn/PRD/...` |
| PLAN | `PLAN_NNN_short_feature_slug.md` | `features/NNN-slug/USnn/PLAN/...` |

## Portable path (1A)

**Portable path** is the only form allowed inside FEATURE / CONTINUITY / STORY / PRD / PLAN / ANALYSIS / ARCH / SEC / memory-bank cites and typed handoffs **written into those artifacts**.

| Storage mode | Form inside artifacts | Example |
|--------------|----------------------|---------|
| **global** | Relative to agent **InstallRoot** | `sdd/blip-api-eventos/features/002-eventos-image-and-gifts/TS01/PRD/002_ts01_loki_forcontext.md` |
| **repository** | Relative to repo root (`$Cwd`) | `features/002-eventos-image-and-gifts/TS01/PRD/002_ts01_loki_forcontext.md` |
| **Same-story siblings** | Relative to current file (allowed) | `../PRD/...`, `./ARCH/...` |
| **Forbidden in artifacts** | OS absolute / user-home InstallRoot | `C:/Users/...`, `<userHome>/<install>/sdd/...` |

**"Full path" in handoffs** means the **portable path** (this section), **not** an OS absolute.

OK to show OS absolute in chat confirm UI / SESSION hashing / sync logs — **not** in written SDD artifact bodies.

Runtime: resolve `InstallRoot` + portable path → absolute **only** at Read/Write time.

### External evidence references for O3

An external source used as evidence may be cited in FEATURE / ANALYSIS / ARCH / PRD / PLAN text as `external:<alias>/<relative-path>` (for example, `external:Demandas/brief/source.md`). This is an evidence reference only; it is not a storage or navigation path. Never put the external root, drive, UNC path, or machine-specific location in an artifact. O1 records the portable reference with the evidence; O2 preserves the exact reference when carrying that evidence into PRD / PLAN and the O3 handoff. O1/O2 do not authorize aliases. Before O3 dispatch, the coordinator must explicitly authorize each alias and provide its root separately to `Invoke-O3ReceiptValidation.ps1`; O3 accepts the reference in `files[]` only when both its alias and path prefix are in coordinator scope. The receipt never carries the root. See `_shared/agents/RECEIPT.md` for the exact path and runtime validation contract.

Classic SDD implementation access is a separate contract: see `CLASSIC-EXTERNAL-ACCESS.md` for user-requested destinations and read/write scope. The shared `external:` spelling does not merge the authority domains: an O3 `files[]` entry remains evidence-only and does not grant Classic read or write access.

## Navigation block (Related)

**Rule IDs:** `NAV-RELATED` · `NAV-OMIT-ABSENT` · `NAV-PORTABLE` (REQ-007 / REQ-008 / RN05 / CA3)

Canonical cross-artifact navigation for FEATURE / CONTINUITY / STORY / PRD / PLAN (and on-disk ANALYSIS / ARCH / SEC pointers). Companion pipeline summary: `PIPELINE.md` § Navigation block.

| Rule | Contract |
|------|----------|
| **Section title** | Exactly `## Related` — **never** `## See also` (RN05) |
| **Paths** | Portable paths only (§ Portable path) — no OS absolute / InstallRoot embeds |
| **Omit-if-absent** | Include a row/bullet **only** when the sibling exists on disk (or is known for the Write in flight). **Do not** create empty stubs solely to satisfy a link |
| **No monolith** | Do **not** invent `feature-refinement.md` as a navigation SoT |

### Modes

| Mode | Edges |
|------|-------|
| **Classic** (`sdd-spec` / `sdd-plan` / `sdd-develop`) | **PRD ↔ PLAN** when either side is written/updated; **STORY** if on-disk; FEATURE / CONTINUITY / ARCH… only if present |
| **Orchestrated O1+** | Bidirectional among siblings that exist: `FEATURE ↔ CONTINUITY ↔ STORY ↔ ANALYSIS\|ARCH\|SEC` (flag-gated / on-disk) `↔ PRD ↔ PLAN` |

### Block shape (templates)

One English-id heading `## Related`, then a table (or bullets) of portable paths. Example (repository mode):

```markdown
## Related

| Relação | Path portátil |
|---------|---------------|
| PRD | `features/003-feature/US01/PRD/003_feature.md` |
| PLAN | `features/003-feature/US01/PLAN/PLAN_003_feature.md` |
| STORY | `features/003-feature/US01/STORY.md` |
```

Omit any row whose target is absent. Slash handoff lines also use portable paths (§ Handoff paths).

**Write obligations** (which skills MUST emit/refresh the block) live in skill SKILL/refs — this section defines the normative block shape and omit rules only. Navigation carries **paths**; readiness/READY severity stays in the WS3 contract (`readiness-severity.md`).

## Handoff paths

Always pass the **portable path** (1A) — never OS absolute / user-home InstallRoot embeds inside artifacts:

```text
/sdd-plan - features/003-feature/US01/PRD/003_feature.md
/sdd-develop - features/003-feature/US01/PLAN/PLAN_003_feature.md - Step 1
```

Global storage example (relative to InstallRoot):

```text
/sdd-plan - sdd/<repo-id>/features/003-feature/US01/PRD/003_feature.md
/sdd-develop - sdd/<repo-id>/features/003-feature/US01/PLAN/PLAN_003_feature.md - Step 1
```

## Forbidden paths (not used)

Do **not** read, write, or continue Classic SDD from:

| Path | Reason |
|------|--------|
| `$Cwd/PRD/`, `$Cwd/PLAN/` | Not part of the active flow (gitignore safety net only) |
| `$Cwd/docs/PRD/`, `$Cwd/docs/PLAN/` | Same |
| `<global>/PRD/`, `<global>/PLAN/` (flat, outside `features/`) | Same |
| Loose `REFINE/` / `ANALYSIS/` / `ARCH/` / `SEC/` at repo root | Must live under `features/NNN-slug/USnn/` |
| `docs/backlog/` | Backlog Refine shortcut drafts only - not canonical PRD/PLAN |
| Generic `docs/*.md`, repo-root markdown without feature tree | Not SDD storage |

When the user cites a non-canonical `.md`: read it, build the artifact per skill templates, confirm path (`PIPELINE.md` § Confirm before write), then `Write` only under `features/NNN-slug/...`.

## Skill responsibilities

| Skill | Storage question | `.gitignore` | Writes |
|-------|------------------|--------------|--------|
| sdd-spec | Yes (confirm path) | Repository mode only | PRD under `features/.../PRD/` |
| sdd-plan | Yes if manifest missing | Repository mode only | PLAN under `features/.../PLAN/` |
| sdd-develop | No - uses PLAN path from input | No | Updates same PLAN file |
| orchestrate-* (Orchestrated Delivery) | Yes if first run | Repository mode only | Feature tree + stories |
| memory-bank-init | Yes (resolve bank root) | Repository mode: SDD block for `features/` etc. only — **not** `/memory-bank/` (commit bank when product knowledge; never commit secrets) | Bank under resolved `bank_root` |
| refine-story | Prefer feature `STORY.md` | No (unless first SDD write) | Optional `docs/backlog/` shortcut |
| split-story-checklist | Prefer feature story folder | No | Task checklist under story / backlog |
| code-review | No | No | Read-only |
| repair-dotnet-build | No | No | Read-only |
| document-plan / document-implement | No | No | `docs/documentation-plan/plan.md` is local workflow state and remains ignored; do not add a negation rule to version it |

---

## Integration

- `ARTIFACT-OWNERSHIP.md` is a navigation/ownership index; specialized contracts below remain normative.
- Pipeline guards: `_shared/sdd-artifacts/PIPELINE.md`
- Session gates: `_shared/sdd-artifacts/SESSION.md`
- Memory Bank Gate: `_shared/sdd-artifacts/MEMORY-BANK.md`
- Feature templates: `_shared/templates/features/`
- Always-on rules: `rules/sdd-pipeline-guards.mdc`, `rules/guardrails.mdc`
