# Feature tree scaffold (Classic SDD / B / C)

Copy this layout under the resolved Classic feature root (`STORAGE.md`):

- **repository:** `$Cwd/features/NNN-slug/`
- **global:** `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/codex/sdd/<repo-id>/features/NNN-slug/`

Do **not** create `REFINE/`, `ANALYSIS/`, `ARCH/`, `SEC/`, `PRD/`, or `PLAN/` at the repository root.

```text
features/NNN-slug/
├── FEATURE.md
├── CONTINUITY.md
└── US01/                         # or TSnn; Classic SDD default = US01
    ├── STORY.md
    ├── REFINE/                   # optional / on demand
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
| `story/STORY.md` | Per-story template (place as `USnn/STORY.md` or `TSnn/STORY.md`) |
| `story/.gitkeep-subfolders` | Lists expected subfolders (`REFINE/` on demand; `ANALYSIS|ARCH|SEC` flag-gated) |

Agent artifact prose default: **pt-BR**. Identifiers and paths: **English**.
