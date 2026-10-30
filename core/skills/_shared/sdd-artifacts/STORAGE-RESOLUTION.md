# SDD storage resolution (schema v2)

Load this reference when selecting repository/global storage, resolving `manifest.json`, preferences, `effective_SDD_ROOT`, or deriving feature and memory-bank roots. The general storage contract remains `STORAGE.md`.

## Global manifest and dynamic storage resolution (schema v2)

> **Used by:** all `sdd-*`, `refine-story`, `split-story-checklist`, and Orchestrated Delivery `orchestrate-*` skills.

### Effective SDD_ROOT

Resolve **before** reading `manifest.json` or any global classic path. Does **not** force repository vs global. Does **not** migrate existing trees. This contract does not name a host.

1. Use the InstallRoot of the current session. Do not follow a skill pack that loaded from a different install.
2. `effective_SDD_ROOT` = `<InstallRoot>/sdd`
3. If a baked absolute `{{SDD_ROOT}}` points at a different install than `effective_SDD_ROOT`, ignore the baked path. Warn once, in the user chat language, that skills from another install were detected and the current install SDD root is in use.
4. Read and write `manifest.json`, `preferences.json`, sessions, and the global classic path only under `effective_SDD_ROOT`.
5. Do not invent a second shared SDD root. One install, one `sdd` folder.

Runtime session and PLAN-ledger scripts derive `effective_SDD_ROOT` from their published location (`<InstallRoot>/scripts/<area>` → `<InstallRoot>/sdd`) when `-SddRoot` is omitted. They must not fall back to a user profile or another adapter installation. Explicit `-SddRoot` / `-SessionsRoot` values remain available to isolated fixtures and callers that deliberately select a root.

Core source keeps the placeholder `{{SDD_ROOT}}`. Publish may bake an absolute. Runtime must apply this override when that absolute is not the current install.

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

Use placeholder / portable paths in docs and **artifact bodies**; never hardcode `C:/Users/<name>/...` or a user-home install path inside FEATURE / CONTINUITY / STORY / PRD / PLAN / ANALYSIS / ARCH / SEC / bank cites.

**Legacy:** older manifests may still contain a `speckit` section. Ignore it; do not require or rewrite it automatically (optional cleanup documented at end of feature 004).

### Preferences location

```
<effective_SDD_ROOT>/preferences.json
```

Toolkit-wide runtime preferences (Caveman Mode, parent orchestrator mode, optional artifact language override). The interactive first-install flow in `toolkit.ps1` asks both preferences only when this file is missing. Non-interactive first sync seeds the defaults below; existing choices are preserved. `sync-agent.ps1` remains non-interactive.

### Preferences structure

```json
{
  "caveman_mode": true,
  "caveman_level": "full",
  "orchestrator_mode": "always",
  "artifact_language": null,
  "verify_mode": false
}
```

| Key | Type | Default | Purpose |
|-----|------|---------|---------|
| `caveman_mode` | bool | `true` | Response compression master switch (`caveman-mode` policy); interactive first-install may choose off |
| `caveman_level` | string | `"full"` | `lite` \| `full` \| `ultra` when mode ON |
| `orchestrator_mode` | string | `"always"` | `always` \| `adaptive` — parent orchestrator policy (`orchestrator-session`) |
| `artifact_language` | string \| null | `null` | Optional SDD artifact language override; when `null`, match user chat per `LANGUAGE.md` |
| `verify_mode` | bool | `false` | When `true`, O3 spawns a read-only verifier child after each implementer returns (`orchestrate-develop` Step 5.5) |

In-session commands update this file (`caveman on|off|…`, `orchestrator always|adaptive|status`). On an interactive first sync, `toolkit.ps1` asks for parent mode (`always`/`adaptive`) and Caveman (`on`/`off`) in the same flow. Caveman on is recommended; off disables response compression. With `WhatIf`, neither prompt nor write occurs. These installation preferences do not select manual versus O3 execution for an individual invocation.

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
   a. Ask user (user chat language) storage for classic SDD (local vs global).
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

### Read, resume, and portable-path resolution

- `features_versioned` controls Git tracking/ignore policy only. It never changes the selected feature root and never controls whether a file is readable. To resume or read an artifact, test/read the exact canonical filesystem path; do not use `git ls-files`, tracked-file enumerations, or any listing that omits ignored files.
- In `repository` mode, a portable artifact path begins with `features/` and resolves under `$Cwd/features/`, whether or not `/features/` is ignored by Git.
- In `global` mode, resolve `classic.path` under `effective_SDD_ROOT`, then resolve the artifact under `<classic.path>/features/`. Its portable cite is relative to InstallRoot (for example, `sdd/<repo-id>/features/...`); map only the prefix corresponding to this configured `classic.path` to the resolved directory. A same-named local `$Cwd/features/` file is a decoy and is not a fallback.
- For both modes, reject traversal and any PRD/PLAN outside the canonical feature/story layout. If the manifest is absent, invalid, has no active-repository entry, or specifies an unsupported mode/path, stop and reconcile storage; do not infer a root from nearby siblings, Git state, a preference, or whichever copy is newest/complete.
- Do not edit the consumer repository `.gitignore` in global mode. Repository-mode ignore guidance is governed by `features_versioned`; reads do not mutate it.

### Resolution checklist (repository vs global)

| Check | repository | global |
|-------|------------|--------|
| Feature root | `$Cwd/features/NNN-slug/` | `<effective_SDD_ROOT>/<repo-id>/features/NNN-slug/` (or manifest path under effective root) |
| Memory-bank root | `$Cwd/memory-bank/` | `<classic.path>/memory-bank/` |
| PRD/PLAN | Under story `PRD/` / `PLAN/` only | Same under global feature root |
| `.gitignore` SDD block | Per `features_versioned` (see § Repository mode); `docs/documentation-plan/plan.md` remains ignored; **not** `/memory-bank/` | Do **not** edit project `.gitignore` |
| Root / flat `PRD/`/`PLAN/` | Not used (ignored if present) | Not used |
| Leading `/` on ignore patterns | Must not ignore `skills/sdd-plan/` or templates | N/A |

### User storage prompt (chat only — mirror user language; pt-BR example below)

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
(docs/documentation-plan/plan.md permanece ignorado em ambos os casos)
```

Persist `features_versioned: true|false` in manifest `classic` section. Apply `.gitignore` block per § Repository mode.
