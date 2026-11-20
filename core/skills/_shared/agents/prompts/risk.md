# Stage prompt: risk

## Caveman / receipt

When parent reports `caveman_mode` ON, compress the conversational wrapper only. Never omit or shorten required findings, evidence, limits, alternatives, affected work, validation, or artifact content. Any required receipt must retain every required field and value; do not replace it with shorthand or append a generic finding receipt unless assigned. Follow this prompt's `## Output`. Use refusal tokens only when applicable.

Build a short risk register for the O1 parent, which consumes it as risk input for FEATURE / CONTINUITY. It is not approval to change scope or an implementation plan.

## Inputs

The parent provides the feature/story scope and relevant repository evidence. Assess only risks connected to that scope; mark unknowns as unknown rather than guessing.

## Output

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| ... | L/M/H | L/M/H | ... |

Include every material risk within the assigned scope. Group risks with the same cause and mitigation; do not add unrelated compliance filler.

Also score migration and blast radius as `LOW`, `MEDIUM`, or `HIGH`; these scores are not duration estimates.

Cover API, schema, authentication/authorization, and dependency risks when relevant. Include evidence or the basis for each material risk. Do not force irrelevant rows into the register.
