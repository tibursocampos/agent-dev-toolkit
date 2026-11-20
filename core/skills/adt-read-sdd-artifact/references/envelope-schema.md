## Envelope (`source_context`)

Return **only** after path validation succeeds and the file exists:

```yaml
source_context:
  schema: RSA-SOURCE-CONTEXT/v1
  artifact_kind: FEATURE | STORY | PRD | PLAN
  portable_path: features/NNN-slug/... | sdd/<repo-id>/features/NNN-slug/... # selected by manifest mode
  identity:
    feature_slug: NNN-slug
    story_id: USnn | TSnn | Bug | null   # null for FEATURE and Delivery PLAN
    file_name: FEATURE.md | STORY.md | <prd|plan file>
  # optional: content may be attached by the caller after Read; identity never depends on a second opaque Read
```

### Canonical kinds (under `features/`)

| Kind | Portable pattern |
|------|------------------|
| `FEATURE` | `features/<NNN-slug>/FEATURE.md` |
| `STORY` | `features/<NNN-slug>/(US\|TS)\d\d/STORY.md` or O1 `features/<NNN-slug>/Bug/STORY.md` |
| `PRD` | `features/<NNN-slug>/(US\|TS)\d\d/PRD/<file>.md` |
| `PLAN` | Classic/O3: `features/<NNN-slug>/(US\|TS)\d\d/PLAN/PLAN_*.md`. Delivery: `features/<NNN-slug>/PLAN.md` or `features/<NNN-slug>/plans/<unit>/PLAN.md` for a selected split unit. |

The consumer explicitly selects the layout. In either layout, the global prefix is derived from the manifest-selected root. The normalized identity does not imply approval, authorize a split, or broaden a Classic/O3 artifact path.
