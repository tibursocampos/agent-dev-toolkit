## Process — Caveman (Lite cap)

1. Read `{{SDD_ROOT}}/preferences.json` (create `{ "caveman_mode": false, "caveman_level": "full" }` if missing).
2. If `caveman_mode` is false: continue without compression.
3. If true: load `{{TOOLKIT_ROOT}}/skills/_shared/caveman/CAVEMAN.md`; apply **Lite** participation cap + prefs `caveman_level` (Lite skills never escalate); show once: `[Caveman] Modo ativo (respostas compactas, level={effective}). Digite caveman off para desativar.`
4. Honor `caveman on|off|status|lite|full|ultra` (and `stop caveman` / `normal mode`) during the session.
5. Auto-Clarity + never-compress gates/drafts/paths per `CAVEMAN.md`.

---

## Process — Resolve storage

Load `STORAGE.md`. Run resolution with `$Workflow = classic`. Resolve feature root and bank root:

- **repository** -> feature `$Cwd/features/`; bank `$Cwd/memory-bank/`
- **global** -> feature `<classic.path>/features/`; bank `<classic.path>/memory-bank/`

**Path sanitize (required)** for any invoke / allocated feature path: normalize (`\` -> `/`, trim trailing `/`, resolve `.`). Reject if it contains `..`, or if the resolved absolute path is **not** under the feature root above. Ask again in pt-BR for a canonical path - do not Read/Write outside the feature root.

If first run for this repo: ask storage (pt-BR) per `STORAGE.md` and persist manifest. Confirm target workspace. Do **not** invent a feature path outside the resolved root.

Repository mode: ensure SDD `.gitignore` patterns per `STORAGE.md` (includes `/features/`; **do not** add `/memory-bank/` — commit bank when product knowledge; never commit secrets) when writing under `features/` or `memory-bank/` (do not weaken toolkit patterns; never ignore `skills/`). **Global mode:** do not edit project `.gitignore`.

---

## Process — Backlog approval + O2 handoff

Before asking: required specialist folders must exist on disk for true flags / brownfield (`ANALYSIS/` / `ARCH/` / `SEC/` per `ROSTER.md`); cited non-feature `.md` must be promoted (not pointer-only). Else **fail O1** — do not present the backlog as ready and do **not** mark approved.

Present the backlog (feature summary + story table with **Rationale** column + scorecard highlights). Ask (pt-BR) — copy in `references/arch-confirm.md` § Approval gate copy.

| Answer | Action |
|--------|--------|
| **sim** | status -> `approved`; continue O2 handoff |
| **ajustar** | revise stories/flags; re-present; ask again |
| **cancelar** | leave `draft`; do not hand off to O2 |
| *(silence / other)* | **not** approval - wait |

On **sim**:

1. Update `FEATURE.md` / story statuses to `approved` as appropriate.
2. Update `CONTINUITY.md`: phase stays `analyze` until O2 starts (or set handoff-ready note); `Last agent` = `orchestrate-analyze`; keep Memory-bank fields; typed handoff string.
3. Offer O2 (document series vs parallel as **O2 choice** - do not implement O2 here) — `references/boundaries-handoff.md` § Canonical handoff strings.

Remind (pt-BR): O2 will ask série vs paralelo for per-story PRD/PLAN.

---

## Process — Context pressure (TE02 / RNF02)

Honor `{{TOOLKIT_ROOT}}/rules/context-management.mdc` thresholds (checkpoint / hard stop). When pressure is high:

1. Persist latest `CONTINUITY.md` (estado atual short per CONTINUITY template, decisões, pendências, exact next `/…`).
2. Offer session handoff - same phase, resume with feature path:

```text
/orchestrate-analyze - <portable-feature-path>
```

Do **not** paste full specialist dumps into the parent chat.
