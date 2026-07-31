# Feature tree scaffold (Forma A / B / C)

Copy this layout under the resolved Classic feature root (`STORAGE.md`):

- **repository:** `$Cwd/features/NNN-slug/`
- **global:** `E:/Source/Repos/agent-dev-toolkit/scripts/validation/fixtures/install-root/sdd/<repo-id>/features/NNN-slug/`

Do **not** create `REFINE/`, `ANALYSIS/`, `ARCH/`, `SEC/`, `PRD/`, or `PLAN/` at the repository root.

```text
features/NNN-slug/
├── FEATURE.md
├── CONTINUITY.md
└── US01/                         # or TSnn; Forma A default = US01
    ├── STORY.md
    ├── REFINE/                   # optional
    ├── ANALYSIS/                 # optional
    ├── ARCH/                     # optional
    ├── SEC/                      # optional
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
| `story/.gitkeep-subfolders` | Lists expected optional subfolders |

Agent artifact prose default: **pt-BR**. Identifiers and paths: **English**.
