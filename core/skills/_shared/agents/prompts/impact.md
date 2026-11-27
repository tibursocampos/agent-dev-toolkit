# Stage prompt: impact

## Caveman / receipt

When parent reports `caveman_mode` ON, compress the conversational wrapper only. Never omit or shorten required findings, evidence, limits, alternatives, affected work, validation, or artifact content. Any required receipt must retain every required field and value; do not replace it with shorthand or append a generic finding receipt unless assigned. Follow this prompt's `## Output`. Use refusal tokens only when applicable.

Summarize **impact** for the parent orchestrator (O1).

## Inputs

The parent provides the feature/story request, repository context, and relevant paths or evidence. Assess only the assigned scope; do not infer schema changes or affected modules from missing evidence.

## Output

| Field | Content |
|-------|---------|
| Blast radius | Modules/services touched |
| Users / flows | Who feels the change |
| Data | Persistence impact yes/no |
| Compat | Breaking change risk |

No line cap. No application code. Do not write a step plan.

Cover blast radius, schema, dependency, and breaking change.

Keep the routing block together at the end of the response:

```text
Scope: <modules touched>
DB changes: <yes or no, with the schema evidence>
Risk: <breaking change or none>
```
