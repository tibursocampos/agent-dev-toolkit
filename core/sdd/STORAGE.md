# SDD artifact storage (sdd-spec / sdd-plan / sdd-develop)

Single source of truth for where Classic SDD and Orchestrated Delivery artifacts are written. Load on demand from skills - do not paste this file into PRD/PLAN bodies.

**Language:** This guideline file is **English**. Default **agent artifact** prose (FEATURE, STORY, PRD, PLAN, CONTINUITY) is **pt-BR** (`sdd-artifact-language-pt-br.mdc`). **Chat** replies and the storage prompt below are **pt-BR** unless the user overrides in the skill invocation.

Install path after sync: `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/STORAGE.md`

## Storage modes

| Mode | Feature root | Memory-bank root |
|------|--------------|------------------|
| **repository** | `$Cwd/features/NNN-slug/` | `$Cwd/memory-bank/` |
| **global** | `<path>/features/NNN-slug/` where `<path>` = `{{SDD_ROOT}}/<repo-id>/` (or manifest `classic.path`) | `<path>/memory-bank/` |

Use `{{SDD_ROOT}}/...` on macOS/Linux when expanding paths in tools.

**Co-location:** `features/` and `memory-bank/` always share the same storage root (`$Cwd` or `<classic.path>`). Never place `memory-bank/` under `features/NNN-slug/`. Contract details: `MEMORY-BANK.md`.

**New writes (Classic SDD / preferred Backlog Refine / Orchestrated Delivery):** only under `features/NNN-slug/` (never loose `REFINE/`, `ANALYSIS/`, `ARCH/`, `SEC/`, `PRD/`, or `PLAN/` at repo root).

**No legacy root flow:** do **not** read, write, glob, or continue develop from repo-root / global-flat `PRD/` or `PLAN/`. Those patterns remain in `.gitignore` only as a safety net against accidental files.

## Feature tree schema

```text
features/NNN-slug/
├── FEATURE.md                 # Feature overview (Orchestrated Delivery / optional Classic SDD)
├── CONTINUITY.md              # Cross-agent / cross-session handoff
├── CHANGE.md                  # Brownfield delta vs current (ADDED|MODIFIED|REMOVED); required when Nature=brownfield — see CHANGE-CONTRACT.md
├── EVD/                       # Post-impl evidence files (evidence-or-zero); see EVD-STATE-CONTRACT.md
├── STATE.md                   # AC → evidence matrix + evidence level (off|cheap|standard|strict)
├── TRACE.jsonl                # Append-only event trail; living loop converge → sync_current → archive (P3); see TRACE-ARCHIVE-CONTRACT.md
└── USnn/ or TSnn/             # Story folder (nn = 01, 02, …)
    ├── STORY.md               # Refined story + scorecard / deps
    ├── REFINE/                # Refine / breakdown scratch (optional / on demand); tasks.md when complexity ≥ medium
    ├── ANALYSIS/              # Impact / risk notes (required when needs_api or brownfield)
    ├── ARCH/                  # Architecture notes (required when needs_domain, needs_database, or brownfield)
    ├── SEC/                   # Security notes (required when needs_security)
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
| `EVD/` | Feature-root evidence folder for post-implementation verify. Required when evidence level ≥ `cheap`. Contract: `EVD-STATE-CONTRACT.md`. |
| `STATE.md` | Feature-root AC → evidence matrix + **Evidence level** (`off` \| `cheap` \| `standard` \| `strict`). Gate via `validate-evidence.ps1`. **Verifier ≠ O3**. |
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
   | `!/docs/documentation-plan/plan.md` | **Always** version `plan.md` (never ignore) |

   **Do not** add or require `/memory-bank/` in the SDD ignore block. Commit bank when product knowledge; never commit secrets.

   Use leading `/` so `skills/sdd-plan/`, `skills/_shared/templates/features/`, `skills/_shared/templates/memory-bank/`, and other non-root paths are **not** ignored.

3. If **any** required pattern for the active `features_versioned` mode is missing, append or migrate the **full** block below. **Remove** legacy `/docs/documentation-plan/` (whole folder) if present — replace with `/*` + `!plan.md`. When `features_versioned` is `true`, **never** re-add `/features/` or `/docs/features/` even if absent from `.gitignore`.

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
   !/docs/documentation-plan/plan.md
   ```

   `features_versioned: true`:

   ```gitignore
   # SDD artifacts (local agent workflow - agent-dev-toolkit)
   /PRD/
   /PLAN/
   /docs/PRD/
   /docs/PLAN/
   /docs/documentation-plan/*
   !/docs/documentation-plan/plan.md
   ```

4. Report: patterns added, migrated, or all already present. If `/memory-bank/` is already present from an older policy, do **not** re-add it; the human may remove it so the bank can be versioned. If the human removed `/features/` manually and manifest has no `features_versioned` yet, ask once and persist the choice.

**CI note:** `Assert-NoFeaturesDocLinks.ps1` assumes `features/` is gitignored by default. When `features_versioned` is `true`, links from published `docs/` to `features/**` are valid.

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
| **Forbidden in artifacts** | OS absolute / user-home InstallRoot | `C:/Users/...`, `<userHome>/.cursor/sdd/...`, `<userHome>/.claude/sdd/...` |

**"Full path" in handoffs** means the **portable path** (this section), **not** an OS absolute.

OK to show OS absolute in chat confirm UI / SESSION hashing / sync logs — **not** in written SDD artifact bodies.

Runtime: resolve `InstallRoot` + portable path → absolute **only** at Read/Write time.

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
| document-plan / document-implement | No | No | **Do not** use this file for `docs/documentation-plan/plan.md` |

---

## Global manifest and dynamic storage resolution (schema v2)

> **Used by:** all `sdd-*`, `refine-story`, `split-story-checklist`, and Orchestrated Delivery `orchestrate-*` skills.

### Effective SDD_ROOT (host-aware)

Resolve **before** reading `manifest.json` or any global classic path. Does **not** force repository vs global — user choice stays. Does **not** migrate existing trees.

1. Detect **current host InstallRoot** for this chat session (not "whichever skill pack happened to load"):

   | Host | InstallRoot |
   |------|-------------|
   | Cursor | `<userHome>/.cursor` |
   | Claude Code | `<userHome>/.claude` |
   | Codex | `<userHome>/.codex` |
   | Copilot | `<userHome>/.copilot` (or documented adapter InstallRoot) |
   | Grok | `<userHome>/.grok` |
   | Antigravity / Gemini | `<userHome>/.gemini` (or adapter InstallRoot) |
   | OpenCode | `~/.config/opencode` (adapter root) |
   | ZCode | `<userHome>/.zcode` |

2. Host detection signals (in order):
   - IDE / product identity in the session
   - Path of **this chat's** primary rules / `AGENTS.md` under an agent home
   - If a loaded skill path is under agent home A but the session is clearly host B, **prefer B**

3. `effective_SDD_ROOT` = `<InstallRoot>/sdd`

4. If a baked absolute `{{SDD_ROOT}}` in the loaded SKILL points under a **different** agent home than `effective_SDD_ROOT`, **ignore the baked path** and use `effective_SDD_ROOT`. Optionally warn once in chat (pt-BR): `Skills de outro agente detectadas; usando SDD do host atual.`

5. Read/write `manifest.json`, `preferences.json`, sessions, and global classic.path **only** under `effective_SDD_ROOT`.

6. Do **not** invent a third shared `~/.agents/sdd` unless already documented — stick to per-agent `InstallRoot/sdd`.

Core source keeps placeholders `{{SDD_ROOT}}`; publish may still bake absolutes. Runtime **must** apply this override when the baked path's agent home ≠ the current host agent home.

### Manifest location

```
<effective_SDD_ROOT>/manifest.json
```

(Docs and core source may still write `{{SDD_ROOT}}/manifest.json`; at runtime expand to `effective_SDD_ROOT`.)

### Manifest structure (v2)

```json
{
  "schema_version": 2,
  "repositories": {
    "D:/Source/Repos/MyApp": {
      "classic": {
        "storage_mode": "global",
        "path": "{{SDD_ROOT}}/MyApp",
        "features_versioned": false
      }
    }
  }
}
```

Use placeholder / portable paths in docs and **artifact bodies**; never hardcode `C:/Users/<name>/...` or user-home InstallRoot embeds (`…/.cursor/sdd/…`, `…/.claude/sdd/…`) inside FEATURE / CONTINUITY / STORY / PRD / PLAN / ANALYSIS / ARCH / SEC / bank cites.

**Legacy:** older manifests may still contain a `speckit` section. Ignore it; do not require or rewrite it automatically (optional cleanup documented at end of feature 004).

### Preferences location

```
<effective_SDD_ROOT>/preferences.json
```

Toolkit-wide runtime preferences (Caveman Mode, orchestrator mode, optional artifact language override). Create on first read when missing — agents and `toolkit.ps1` seed the default schema below.

### Preferences structure

```json
{
  "caveman_mode": false,
  "caveman_level": "full",
  "orchestrator_mode": "always",
  "artifact_language": null,
  "verify_mode": false
}
```

| Key | Type | Default | Purpose |
|-----|------|---------|---------|
| `caveman_mode` | bool | `false` | Response compression master switch (`caveman-mode` policy) |
| `caveman_level` | string | `"full"` | `lite` \| `full` \| `ultra` when mode ON |
| `orchestrator_mode` | string | `"always"` | `always` \| `adaptive` — parent orchestrator policy (`orchestrator-session`) |
| `artifact_language` | string \| null | `null` | Optional SDD artifact language override; when `null`, match user chat per `LANGUAGE.md` |
| `verify_mode` | bool | `false` | When `true`, O3 spawns a read-only verifier child after each implementer returns (`orchestrate-develop` Step 5.5) |

In-session commands update this file (`caveman on|off|…`, `orchestrator always|adaptive|status`). Interactive first sync via `toolkit.ps1` may prompt for orchestrator mode when the file is missing.

### Legacy migration (v1 -> v2)

If a repository entry has top-level `storage_mode` and `path` (no `classic`), migrate in memory:

```json
{
  "classic": { "storage_mode": "repository", "path": "D:/Source/Repos/MyApp" }
}
```

**Persist migration:** TBD — no shipped `migrate-manifest-v2` script in this toolkit. Apply the mapping **in memory** on read; write the v2 `classic` shape back on the first skill run that updates the manifest.

### Resolution algorithm

Execute at skill load time, before any read or write. Parameter: `$Workflow` = `classic` (only supported workflow).

```
0. Resolve effective_SDD_ROOT (host-aware) — see section above.
1. Normalize $Cwd (replace \ with /, trim trailing /).
2. Read manifest.json from effective_SDD_ROOT; ensure schema_version = 2
   (migrate v1 if needed).
3. Look up repositories[$Cwd].
4. If NOT found (first run):
   a. Ask user (pt-BR) storage for classic SDD (local vs global).
   b. Write classic section only (under effective_SDD_ROOT).
   c. Set session gate storage_confirmed = true after user sim.
5. If found: read repositories[$Cwd].classic.storage_mode, .path, and
   .features_versioned (default false if absent; ignore any legacy speckit key).
6. Derive classic feature root and memory-bank root:
   - repository -> feature_root = $Cwd/features/
                    bank_root   = $Cwd/memory-bank/
   - global     -> feature_root = <classic.path>/features/
                    bank_root   = <classic.path>/memory-bank/
   (global paths must resolve under effective_SDD_ROOT; never under a foreign agent home).
7. For classic feature writes and reads: resolve only under
   features/NNN-slug/[USnn|TSnn]/{PRD|PLAN|...}
   (Classic SDD default story = US01 when unspecified).
   Never use repo-root or global-flat PRD/ / PLAN/.
8. For memory-bank writes/reads: only under bank_root (never under features/NNN-slug/).
```

### Physical path mapping

| storage_mode | Classic feature root | Memory-bank root | Classic PRD | Classic PLAN |
|---|---|---|---|---|
| `repository` | `$Cwd/features/` | `$Cwd/memory-bank/` | `$Cwd/features/NNN-slug/USnn/PRD/` | `$Cwd/features/NNN-slug/USnn/PLAN/` |
| `global` | `<path>/features/` | `<path>/memory-bank/` | `<path>/features/NNN-slug/USnn/PRD/` | `<path>/features/NNN-slug/USnn/PLAN/` |

`<path>` = `repositories[$Cwd].classic.path`

### Resolution checklist (repository vs global)

| Check | repository | global |
|-------|------------|--------|
| Feature root | `$Cwd/features/NNN-slug/` | `<effective_SDD_ROOT>/<repo-id>/features/NNN-slug/` (or manifest path under effective root) |
| Memory-bank root | `$Cwd/memory-bank/` | `<classic.path>/memory-bank/` |
| PRD/PLAN | Under story `PRD/` / `PLAN/` only | Same under global feature root |
| `.gitignore` SDD block | Per `features_versioned` (see § Repository mode); always `!/docs/documentation-plan/plan.md`; **not** `/memory-bank/` | Do **not** edit project `.gitignore` |
| Root / flat `PRD/`/`PLAN/` | Not used (ignored if present) | Not used |
| Leading `/` on ignore patterns | Must not ignore `skills/sdd-plan/` or templates | N/A |

### User storage prompt (chat only - pt-BR)

Ask before the first write of Classic artifacts in the session (unless manifest applies):

```text
Onde gravar artefatos SDD (features/ + memory-bank/) deste projeto?

1) Repositório - na raiz do projeto (features/, memory-bank/)
2) Global - {{SDD_ROOT}}/<RepositoryName>/ (features/ + memory-bank/ fora do git do projeto; sem alterar .gitignore)
```

If **repository** (step 1), ask next:

```text
Versionar artefatos SDD em features/ e docs/features/ no git deste repositório?

1) Não (padrão) — /features/ e /docs/features/ no .gitignore
2) Sim — features/ e docs/features/ versionadas; safety-net para PRD/PLAN soltos na raiz
(docs/documentation-plan/plan.md sempre versionado em ambos os casos)
```

Persist `features_versioned: true|false` in manifest `classic` section. Apply `.gitignore` block per § Repository mode.

## Integration

- Pipeline guards: `_shared/sdd-artifacts/PIPELINE.md`
- Session gates: `_shared/sdd-artifacts/SESSION.md`
- Memory Bank Gate: `_shared/sdd-artifacts/MEMORY-BANK.md`
- Feature templates: `_shared/templates/features/`
- Always-on rules: `rules/sdd-pipeline-guards.mdc`, `rules/guardrails.mdc`
