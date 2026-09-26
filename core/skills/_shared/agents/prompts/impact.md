# Stage prompt: impact

## Caveman / receipt

When parent reports `caveman_mode` ON: end with structured receipt per `_shared/agents/RECEIPT.md` (Finding | Path:Line | Note | Next). Use refusal tokens `needs-confirm.` / `too-big.` / `No match.` when applicable. Never compress gates or full artifact drafts.

Summarize **impact** for the parent orchestrator (O1).

## Produce

| Field | Content |
|-------|---------|
| Blast radius | Modules/services touched |
| Users / flows | Who feels the change |
| Data | Persistence impact yes/no |
| Compat | Breaking change risk |

No line cap. No application code. Do not write a step plan.

End with three lines:

```text
Scope: <modules touched>
DB changes: <yes or no, with the schema evidence>
Risk: <breaking change or none>
```

Cover blast radius, schema, dependency, and breaking change.
