# 06 — Framework upgrade

Skill id is **`framework-upgrade`**. It is not renamed per product or major (`dotnet10-upgrade`, `angular-v*-upgrade`, and `framework-upgrade-vN` are forbidden). The target version is an argument of a pack.

Trigger: `/framework-upgrade`, or an explicit mode.

## Modes

If the mode is omitted, ask once. Never assume `migrate`.

| Mode | Writes application code? | Gate |
|------|--------------------------|------|
| `audit` | No | Optional confirm. Inventory versus `supported_range`. Suggests `plan` |
| `plan` | No (decision register only if the operator asked to persist it) | Confirm scope. Baby steps from current to target. A plan is not permission to migrate |
| `migrate` | Yes, one hop at a time | **sim** required. Silence is not approval. Plan approval is not migrate approval |
| `validate` | No | Pack build and test signals, evidence matrix pass or fail. Does not escalate into migrate |

```text
audit → plan → sim → migrate → validate
              ↘ validate on a tree that was already migrated
```

Stop after one session outcome. Do not chain an unrelated skill. `/commit` only if the operator wants it. `/code-review` only if the operator asks.

## Packs

Registry: `core/skills/framework-upgrade/packs/REGISTRY.md`.

| Pack | On disk | After upgrade, quality notes point at |
|------|---------|----------------------------------------|
| `angular` | Yes (`packs/angular/PACK.md`) | `core/skills/_shared/angular-guidelines/` |
| `dotnet` | Yes (`packs/dotnet/PACK.md`). TFM and SDK are parameters. Practice band 8–10 | `core/skills/_shared/dotnet-guidelines/` |
| `python`, `node`, `react` | Not shipped as packs yet | Add a folder under `packs/<id>/`. Do not add a new skill id |

Detection uses each pack’s own signals. Zero matches or more than one: ask. Do not guess `framework_id`.

`targetVersion` must be greater than `currentVersion`. Outside `supported_range`: research protocol, official sources, stop. Do not invent deltas in the session. Extending the range is a pack change, not a new skill.

The upgrade skill loads one pack section per hop. It does not dump guideline trees. Those trees are for the later quality pass and for [stack skills](04-implement-and-guidelines.md).

## What this skill refuses

ADO work-item mutation, duration or story-point estimates, and baking a single company’s brand into the pack. Unofficial blogs do not override official docs.
