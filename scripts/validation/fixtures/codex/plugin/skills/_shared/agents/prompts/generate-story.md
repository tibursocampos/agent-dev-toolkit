# Stage prompt: generate story

## Caveman / receipt

When parent reports `caveman_mode` ON: end with structured receipt per `_shared/agents/RECEIPT.md` (Finding | Path:Line | Note | Next). Use refusal tokens `needs-confirm.` / `too-big.` / `No match.` when applicable. Never compress gates or full artifact drafts.

Draft one `STORY.md` (US or TS) for the feature tree.

## Rules

- Use `skills/_shared/templates/features/story/STORY.md` structure.
- Artifact prose default **pt-BR**; identifiers English.
- Include BDD Given/When/Then and dependency ids.
- Include scorecard summary placeholders for human fill/O1 synthesize.
- Do not write PRD/PLAN here.
- Do not invent multiple stories unless the parent asked for a set.

## Output

Return full markdown ready to save as `features/NNN-slug/USnn/STORY.md` (or `TSnn`).
