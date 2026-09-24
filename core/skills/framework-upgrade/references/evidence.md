# Evidence gates — framework-upgrade

Before claiming `migrate` hop done or `validate` success, attach observable evidence.

## Levels (align with toolkit EVD when a feature wave uses it)

| Level | Meaning for this skill |
|-------|------------------------|
| `off` | Docs/orchestration-only session; still report what was checked |
| `cheap` | Structural: files exist, grep gates, targeted build/test named |
| `standard` | cheap + pack validation checklist |
| `strict` | standard + full suite / release gates per pack |

Default for mid-upgrade orchestration when no feature EVD is in play: **`cheap`** checks in the report (commands + exit codes), without inventing EVD folders unless the feature PLAN requires them.

## Minimum before “done”

| Claim | Evidence |
|-------|----------|
| Pack resolved | Path to `PACK.md` + detect signals used |
| Version pair valid | `target > current`; in-range or research outcome recorded |
| Migrate hop applied | Diff summary + decision register entry + operator **sim** |
| Validate passed | Named build/test commands + exit 0 (or documented skip with operator **sim**) |

## Must not

- Mark migrate complete on silence
- Use LLM-only “looks good” as the sole validator when a deterministic command exists
- Add duration/effort estimates as evidence
