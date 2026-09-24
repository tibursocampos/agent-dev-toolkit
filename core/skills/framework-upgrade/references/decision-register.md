# Decision register — framework-upgrade

Observable log of upgrade decisions. Keep entries short; cite portable paths.

## When to write

| Mode | Requirement |
|------|-------------|
| `audit` | Optional (notable ambiguities only) |
| `plan` | **Required** — one entry per planned hop / open question |
| `migrate` | **Required** — one entry per applied hop + operator **sim** timestamp/note |
| `validate` | Required when a gate fails or a deviation is accepted |

## Entry shape (chat and/or persisted artifact)

```text
[decision] id=<n> mode=<audit|plan|migrate|validate>
  pack=<framework_id> current=<ver> target=<ver>
  choice=<summary>
  rationale=<one line>
  evidence=<path or "none">
  operator_sim=<yes|no|n/a>
```

## Rules

- Register must remain **readable in-session** (chat summary and/or feature-local note path the operator approved).
- Do not invent decisions the operator did not confirm.
- Silence on migrate → `operator_sim=no` → do not apply mutate.
- No duration / effort / story-point fields (RN04).

## Stub persistence (optional)

If the operator asks to persist: prefer a portable path under the active feature (`features/.../`) or a project-agreed upgrade note — never a branded external filename. Packs may refine the path later.
