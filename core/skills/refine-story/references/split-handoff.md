## Relationship to split-story-checklist

| Skill | Use |
|-------|------|
| `refine-story` | Produces steps under `### Steps` (or Bug suggested fix) with deps; envelope `mode: split` + Q&A history when clarifying |
| `split-story-checklist` | Groups those steps with topological / layer grouping into a checklist |

After refine (especially mode `split`), offer with a **portable** path only:

```
/split-story-checklist - features/NNN-slug/USnn/STORY.md
```

When Q&A history exists, cite it in the typed handoff (do not paste full history):

```
qa_history: features/NNN-slug/USnn/REFINE/qa-history.md
```

If envelope `status` is `NEEDS_CLARIFICATION`, do **not** claim the item is READY for PRD — checklist handoff for step shaping may still proceed when steps themselves are the ask.

---
