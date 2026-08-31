## SDD artifact resolution

Run in **step 0.5** before scoping the diff. Load `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/STORAGE.md`. On Windows, `{{SDD_ROOT}}/` is `{{SDD_ROOT}}/`.

### Checklist

1. **Target repo** - open workspace is the project under review (not this toolkit repo unless that is the subject).
2. **`<repo-id>`** - per `STORAGE.md`: `git remote get-url origin` -> slug; else workspace root basename; reuse `repo_id` from manifest when present.
3. **Manifest** - read `{{SDD_ROOT}}/<repo-id>/manifest.json` when it exists and `workspace_root` (normalized separators, case-insensitive on Windows) matches the open workspace -> derive classic feature root from `STORAGE.md` (repository `features/` or global `.../features/`).
4. **Glob** (parallel) - **only** under `features/` (never root/flat `PRD/` or `PLAN/`):

   | Location | Patterns |
   |----------|----------|
   | Workspace | `features/**/PRD/*.md`, `features/**/PLAN/PLAN_*.md`, `docs/features/**/PRD/*.md`, `docs/features/**/PLAN/PLAN_*.md` |
   | Global | `{{SDD_ROOT}}/<repo-id>/features/**/PRD/*.md`, `{{SDD_ROOT}}/<repo-id>/features/**/PLAN/PLAN_*.md` |

5. **Extract `NNN`** - first three digits from PRD filename (`001_...md`) and from PLAN (`PLAN_001_...md`).
6. **Pair** - match PRD and PLAN with the same `NNN`.
7. **Select one pair** (first match wins):

   | Priority | Signal |
   |----------|--------|
   | 1 | User passed explicit PRD or PLAN path in invocation |
   | 2 | PLAN header field **PRD** points to a discovered PRD path |
   | 3 | `NNN` or feature slug aligns with current branch name |
   | 4 | Single pair after pairing |
   | 5 | Ask once in pt-BR - numbered list of PRD + PLAN paths |

8. **Read** selected PRD and PLAN before SDD traceability (step 2).
9. **Report** - always record full paths used (workspace-relative or absolute global).

### Outcomes

| Result | Action |
|--------|--------|
| One pair found | Proceed with SDD traceability |
| No artifacts after full search | Report **Limitação SDD** (technical/guidelines review only); do not state PRD/PLAN "do not exist" |
| Multiple ambiguous pairs | Ask user once; then proceed |

---

---
