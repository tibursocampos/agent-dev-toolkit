# Skill boilerplate - shared gates

Every skill loads this file before its first tool call. The skill body adds only its own steps. Do not copy these rules into `SKILL.md`; point to this file instead.

## STOP - Read before ANY tool call

1. Read `{{GUARDRAILS_PATH}}` (always mandatory).
2. Session state: read `_shared/sdd-artifacts/SESSION.md` before any tool call (mandatory, same as guardrails STOP step 2). Gate checks and gate writes apply only where a session gate covers the action; use `_shared/sdd-artifacts/INDEX.md` to decide which SESSION sections to apply.
3. If the relevant gate is not approved: **STOP** and ask the user in the **user chat language** (`_shared/agents/LANGUAGE.md`). Do **NOT** Write or run Shell.
4. SDD and develop skills: after **ONE** step or task, **STOP** the develop scope. Hand off only.
5. The skill body is **English**. User-facing prompts follow the **user chat language** (`_shared/agents/LANGUAGE.md`).

### Step -1 - Gate check (report in chat before continuing)

Report only the items that apply to the current action:

```
Gate check:
[ ] guardrails read
[ ] SESSION.md loaded (mandatory; gate sections per sdd-artifacts/INDEX.md)
[ ] PIPELINE.md read, only when sdd-artifacts/INDEX.md requires it (SDD skills; required for orchestrate-*)
[ ] User confirmed current action (sim), when the action writes or runs a gated step
-> If any applicable item is unchecked: STOP
```

## Negative signal

Do not activate a skill when the request lacks one of its positive signals or its required context. Topic similarity or an isolated keyword alone is insufficient.
