## Parsing steps from refined markdown

| Item type | Section headings to search |
|-----------|
| User Story / Technical Story | `### Steps` (emoji heading variants allowed) |
| STORY.md | `## Steps` or steps embedded after description |
| Bug | `### Suggested fix` or `### Steps` |

Each step block typically matches:

```markdown
**Step N - [Title]**
[description]
- Layer: [...]
- Depends on: [...]
```

Also accept legacy Portuguese headings: `**Etapa N -` (normalize to Step N in output).

If only a bullet list without step headers, ask the user to re-run `refine-story` or confirm grouping manually.

## `source=prd`

When the parent is `sdd-plan`, the argument is `source=prd`. The source is the closed STORY and the closed PRD, not a text that is already sliced.

If that source has no step headings, create groups from the PRD `REQ` rows. One group may cover more than one REQ when they are the same outcome. Do not return "call refine-story". Dependencies, waves, and parallel-safe stay in `topology-grouping.md`. Write `features/NNN-slug/{USnn|TSnn}/REFINE/tasks.md` per `output-template.md`.

The PLAN copies these step ids. It does not invent another step size.

---
