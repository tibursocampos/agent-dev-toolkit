## Optional save: feature STORY (preferred)

```markdown
# STORY: US01 - [title]
...
```

Use `skills/_shared/templates/features/story/STORY.md`. Place under `features/NNN-slug/USnn/STORY.md`. Optional raw refine dump: `features/NNN-slug/USnn/REFINE/refine.md`.

Do **not** create `REFINE/` at repo root.

---

## Optional save: `docs/backlog/<slug>.md` (shortcut)

Prefix file with metadata:

```markdown
# Backlog: [title]

| Field | Value |
|-------|--------|
| **Type** | Bug \| User Story \| Technical Story |
| **Doc language** | pt-BR \| English |
| **Refined** | YYYY-MM-DD |
| **Repository** | [folder or remote name] |
| **Preferred promote** | features/NNN-slug/USnn/STORY.md |

[generated body]
```

Do not create `docs/backlog/` in **this toolkit repo** during toolkit porting - only in consumer repos at runtime.

---
