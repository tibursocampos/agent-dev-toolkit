# Modes — framework-upgrade

Four modes only. Skill id remains `framework-upgrade` in every mode.

| Mode | Mutating writes | Operator gate | Primary refs |
|------|-----------------|---------------|--------------|
| `audit` | No | Optional confirm to start | progressive-load, version-policy |
| `plan` | No (docs/register only if operator asked to persist plan artifacts) | Confirm scope | decision-register, progressive-load |
| `migrate` | Yes | **Explicit sim required** — silence ≠ approval (RN02 / TE05) | decision-register, evidence, pack deltas |
| `validate` | No (except test/fix logs if project requires) | Confirm scope | evidence, pack validation |

## Contracts

### audit

- Inventory current framework signals, versions, and gap vs `supported_range`.
- Output: findings + recommended next mode (`plan` typical).
- Must not change application source.

### plan

- Produce ordered baby steps for `currentVersion` → `targetVersion`.
- Append entries to the decision register (observable).
- Plan ≠ execute: do **not** enter migrate without a new **sim**.

### migrate

- Apply one hop / step at a time per pack cascade rules.
- **STOP** before first mutate if operator has not said **sim** for migrate.
- After each hop: update decision register; run evidence gates before claiming hop done.
- Zero duration/effort checkpoints (see `skip-policy.md`).

### validate

- Run pack-defined build/test/validation signals.
- Fill evidence matrix; report pass/fail.
- Must not silently escalate into migrate.

## Transitions

```
audit → plan → (sim) → migrate → validate
              ↘ validate (read-only verify of existing tree)
```

Illegal: `* → migrate` without explicit **sim**. Illegal: treating plan approval as migrate approval.
