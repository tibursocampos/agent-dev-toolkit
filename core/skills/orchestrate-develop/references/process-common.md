## Process — Caveman (Full cap)

1. Read `{{SDD_ROOT}}/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full" }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md`; apply **Full** participation cap + prefs `caveman_level` (Lite skills never escalate); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) during the session.
5. Auto-Clarity + never-compress gates/drafts/paths per `CAVEMAN.md`.

---

## Process — Resolve feature / PLAN set

Load `STORAGE.md` (`$Workflow = classic`). Resolve feature root and `bank_root` (repository vs global per `STORAGE.md` / `MEMORY-BANK.md`).

**Path sanitize (required):** normalize invoke paths; reject `..` and any resolved path outside `$Cwd/features/` (repository) or `<classic.path>/features/` (global). For a single PLAN path, it must remain under that features root. Ask again in pt-BR if invalid.

Repository mode: ensure SDD `.gitignore` per `STORAGE.md` before any bank write. **Global:** do not edit `.gitignore`.

| Invoke | Action |
|--------|--------|
| Feature path | Glob `**/PLAN/PLAN_*.md` under that feature; build story/PLAN queue |
| Single PLAN path | Work that PLAN only; still update feature `CONTINUITY.md` if present |
| Missing PLAN | **STOP** - suggest O2 or Classic SDD |

```text
Não encontrei PLAN sob `{path}`.

1) /orchestrate-deliver - <portable-feature-path>
2) /sdd-plan - <portable-prd-path>
3) cancelar
```

`Read` `FEATURE.md` + `CONTINUITY.md` when under a feature. Prefer O2-approved stories; if PLAN exists but approval unclear, ask once (pt-BR) before spawning.
