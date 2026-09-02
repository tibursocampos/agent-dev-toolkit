## Envelope (`source_context`)

Return **only** after path validation succeeds and the file exists:

```yaml
source_context:
  schema: RSA-SOURCE-CONTEXT/v1
  artifact_kind: FEATURE | STORY | PRD | PLAN
  portable_path: features/NNN-slug/...   # portable only — never OS absolute
  identity:
    feature_slug: NNN-slug
    story_id: USnn | TSnn | null         # null for FEATURE.md at feature root
    file_name: FEATURE.md | STORY.md | <prd|plan file>
  # optional: content may be attached by the caller after Read; identity never depends on a second opaque Read
```

### Canonical kinds (under `features/`)

| Kind | Portable pattern |
|------|------------------|
| `FEATURE` | `features/<NNN-slug>/FEATURE.md` |
| `STORY` | `features/<NNN-slug>/(US\|TS)\d\d/STORY.md` |
| `PRD` | `features/<NNN-slug>/(US\|TS)\d\d/PRD/<file>.md` |
| `PLAN` | `features/<NNN-slug>/(US\|TS)\d\d/PLAN/PLAN_*.md` |

Global classic: same suffix after `sdd/<repo-id>/` — strip that prefix before kind match; still require the `features/` segment.
