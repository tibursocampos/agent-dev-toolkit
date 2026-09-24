# type_classification + exact-set → STORY only

**REQ-012 / CA4 / CT4.** Contract id: `type_classification`. Load **after** Step 0 source parse and **before** checklist Write (Step 3). Applies to `/split-story-checklist` when the source is (or resolves to) a feature story folder.

**Language:** English identifiers and reason codes. Operator chat follows session language (`LANGUAGE.md`). Portable paths only (`STORAGE.md` § Portable path).

Companions: `references/parsing.md`, `references/output-template.md`, `references/exclusions.md`, `references/sdd-handoff.md`, `_shared/backlog-item-types/` (load **one** type file only), `anti-task-shatter.md`.

---

## Purpose

Resolve the backlog **item type** once, then persist the **exact-set** of classification fields **only** on `STORY.md`. The checklist (`REFINE/tasks.md` / `TASKS.md` / shortcut) stays SMART engineering rows — it must **not** fork or restate the type exact-set.

## Exact-set (normative)

| Field | Allowed values | Where it may be written |
|-------|----------------|-------------------------|
| `item_type` | `Bug` \| `User Story` \| `Technical Story` | **STORY only** |
| Story folder **Tipo** shorthand | `Bug` \| `US` \| `TS` | **STORY only** (same classification; map US↔User Story, TS↔Technical Story) |

**Exact-set** = the resolved `{ item_type, Tipo }` pair for this story. One canonical write surface: `features/NNN-slug/USnn/STORY.md` (or global portable equivalent under the feature root).

### Write rules

| Do | Do not |
|----|--------|
| Update STORY header **Tipo** (and narrative type line if present) when classification changes or was missing | Copy `item_type` / **Tipo** / type enums into `REFINE/tasks.md`, `TASKS.md`, or shortcut checklists |
| Cite portable STORY path in chat summary | Dump type exact-set into `FEATURE.md`, `CONTINUITY.md`, `CHANGE.md`, `PLAN_*.md`, or `PRD` |
| Load **one** matching type template under `_shared/backlog-item-types/` for parse hints | Invent a second SoT for type (envelope fork, tracker card, parallel markdown) |
| Keep checklist **Altitude** = SMART tasks under the parent story | Promote steps to new `USnn`/`TSnn` from type labels |

### When source is not a feature STORY

| Source | Classification | Exact-set Write |
|--------|----------------|-----------------|
| `features/.../STORY.md` | Required | Update that STORY only |
| `docs/backlog/*.md` or paste/chat | Resolve type in chat; ask once if ambiguous | **No** STORY Write unless operator points at a portable STORY path |
| Missing type cues | Ask once: Bug \| User Story \| Technical Story | Write STORY only after path + answer known |

## Observable flow

```text
Step 0 parse Steps / Suggested fix
  → type_classification (resolve item_type + Tipo)
  → exact-set Write → STORY.md only (when under features/)
  → Step 1 language → Step 2 topology → Step 3 checklist Write (no type exact-set)
  → Step 4 summarize (cite STORY path + type; checklist path separate)
```

## Resolution order

1. STORY header **Tipo** / explicit `item_type` / refine envelope `item_type` (when cited by portable path — do not paste full envelope)
2. Heading / template cues (`Bug`, `User Story`, `Technical Story`, `US`/`TS`)
3. Operator answer (ask once)
4. If still unresolved → **STOP** with reason `type_unresolved` — do not Write checklist or invent type

Map: `US` → User Story; `TS` → Technical Story; `Bug` → Bug.

## Skip D (REQ-013 / CA4) — explicit

This skill **must not** introduce or invoke:

| Forbidden (Skip D) | Why |
|--------------------|-----|
| **ADO mutate** / Azure Boards WI create-update | OOS WS13; no work-item side effects from classification |
| **Reversa** constitution / skill trees | OOS; not a second SoT |
| **SpecKit constitution** / `.specify/` / uv / specify installers | Credits may mention inspiration elsewhere; **do not** adopt here |

Also forbidden: renaming skill id / slash (`split-story-checklist` stable — RN03); inventing `framework-upgrade` or Jarvis/`JARVIS_*` names.

## STOP / reason codes

| Code | When |
|------|------|
| `type_unresolved` | Cannot classify after cues + one ask |
| `exact_set_scatter` | Diff would write type exact-set outside STORY |
| `classification_skip_d_violation` | Prompt/diff would add ADO mutate, Reversa, or SpecKit constitution |
| `skill_id_drift` | Attempt to rename skill id or `/split-story-checklist` |

## Skill wiring

| Consumer | When to load |
|----------|----------------|
| `split-story-checklist` | After Step 0; before Step 3 Write |
| `refine-story` handoff | Points here via `/split-story-checklist - <portable-STORY>` — refine does not own checklist exact-set Write |
| O2 / O3 | Consume STORY **Tipo**; do not re-classify into PLAN/PRD |

## CT4 checklist (manual — split half)

- [ ] Contract file present: `references/type-classification.md` with markers `type_classification`, `exact-set`, `STORY only`
- [ ] SKILL Process loads this ref before checklist Write
- [ ] Checklist template / output forbids type exact-set fork
- [ ] Skip D: zero ADO mutate / Reversa / SpecKit in this skill folder for the step
- [ ] Frontmatter `name: split-story-checklist` and slash `/split-story-checklist` unchanged

## Must not

- Scatter exact-set outside STORY (REQ-012)
- ADO mutate, Reversa, SpecKit constitution (Skip D / REQ-013)
- Create a new skill folder or rename this skill (RN03)
- Emit one US/TS per file from type labels (`anti-task-shatter.md` / RN01)
