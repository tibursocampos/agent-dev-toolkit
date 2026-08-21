# Feature tree scaffold (Classic SDD / Backlog Refine / Orchestrated Delivery)

Copy this layout under the resolved Classic feature root (`STORAGE.md`):

- **repository:** `$Cwd/features/NNN-slug/` (artifact cite: `features/NNN-slug/…`)
- **global:** InstallRoot + `sdd/<repo-id>/features/NNN-slug/` (artifact cite: `sdd/<repo-id>/features/NNN-slug/…` — portable path; see `STORAGE.md` § Portable path)

Do **not** create `REFINE/`, `ANALYSIS/`, `ARCH/`, `SEC/`, `PRD/`, or `PLAN/` at the repository root.

```text
features/NNN-slug/
├── FEATURE.md
├── CONTINUITY.md
├── CHANGE.md                     # brownfield vs current (ADDED|MODIFIED|REMOVED); skip empty stub on greenfield
├── EVD/                          # post-impl evidence (evidence-or-zero); see EVD-STATE-CONTRACT.md
├── STATE.md                      # AC → evidence matrix + evidence level (off|cheap|standard|strict)
├── TRACE.jsonl                   # append-only event trail; living loop converge → sync_current → archive
└── US01/                         # or TSnn; Classic SDD *(formerly Forma A)* default = US01
    ├── STORY.md
    ├── REFINE/                   # optional / on demand; tasks.md when complexity ≥ medium
    ├── ANALYSIS/                 # required when needs_api or brownfield
    ├── ARCH/                     # required when needs_domain, needs_database, or brownfield
    ├── SEC/                      # required when needs_security
    ├── PRD/
    │   └── NNN_short_slug.md
    └── PLAN/
        └── PLAN_NNN_short_slug.md
```

| File in this folder | Role |
|---------------------|------|
| `FEATURE.md` | Feature overview template |
| `CONTINUITY.md` | Cross-agent continuity template |
| `CHANGE.md` | Brownfield delta vs current (`memory-bank/` living docs); see `CHANGE-CONTRACT.md` |
| `EVD/` | Post-impl evidence folder scaffold (`EVD/README.md`); see `EVD-STATE-CONTRACT.md` |
| `STATE.md` | AC → evidence matrix + evidence level template; see `EVD-STATE-CONTRACT.md` |
| `TRACE.jsonl` | Append-only TRACE scaffold; see `TRACE-ARCHIVE-CONTRACT.md` |
| `story/STORY.md` | Per-story template (place as `USnn/STORY.md` or `TSnn/STORY.md`) |
| `story/.gitkeep-subfolders` | Lists expected subfolders (`REFINE/` on demand; `ANALYSIS|ARCH|SEC` flag-gated) |

Agent artifact prose default: **pt-BR**. Identifiers and paths: **English**.
