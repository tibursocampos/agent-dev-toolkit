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

---
