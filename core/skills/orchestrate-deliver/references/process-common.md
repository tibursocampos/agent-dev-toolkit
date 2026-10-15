## Process — Caveman (Lite cap)

1. Read `{{SDD_ROOT}}/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full" }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md`; apply **Lite** participation cap + prefs `caveman_level` (Lite skills never escalate); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) during the session.
5. Auto-Clarity + never-compress gates/drafts/paths per `CAVEMAN.md`.

---

## Process — Resolve feature and storage

Load `STORAGE.md` + `STORAGE-RESOLUTION.md`. Run resolution with `$Workflow = classic`.

Accept feature path from invoke (preferred) or Glob under feature root:

- **repository** -> `$Cwd/features/NNN-slug/`; bank `$Cwd/memory-bank/`
- **global** -> `<classic.path>/features/NNN-slug/`; bank `<classic.path>/memory-bank/`

**Path sanitize (required):** normalize the invoke path (`\` -> `/`, trim trailing `/`, resolve `.`). Reject if it contains `..`, or if the resolved absolute path is **not** under `$Cwd/features/` (repository) or `<classic.path>/features/` (global). Ask again in pt-BR for a canonical path - do not Read/Write outside the feature root.

Repository mode: ensure SDD `.gitignore` per `STORAGE.md` and `features_versioned` in manifest before writes under feature or bank roots (**do not** add `/memory-bank/`; keep `docs/documentation-plan/plan.md` ignored without a negation rule). **Global:** do not edit `.gitignore`.

`Read` `FEATURE.md` + `CONTINUITY.md`. If missing: **STOP** - ask for O1 first:

```text
Não encontrei FEATURE.md / CONTINUITY.md em `{path}`.

1) /orchestrate-analyze - <portable-feature-path>
2) cancelar
```

---

## Process — Durable progress handoff

Checkpoint durable workflow progress at the workflow-defined boundaries; context usage does not add a stop gate.

1. Persist `CONTINUITY.md` (estado, decisões, which stories done/pending, exact next invoke).
2. Offer resume:

```text
/orchestrate-deliver - <portable-feature-path>
```

Do **not** paste full PRD/PLAN bodies into the parent chat.
