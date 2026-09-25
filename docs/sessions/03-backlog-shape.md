# 03 — Backlog shape

Two skills shape a backlog item. Orchestrated Delivery already performs the product rules **inside** [O1](01-orchestrated-delivery.md) without invoking these skills. Standalone use is for someone who is writing tasks or one story and is not running a feature through O1–O3.

## What O1 already does

| Rule | File loaded by O1 | Standalone skill |
|------|-------------------|------------------|
| Scorecard /100 mapped to 1–5 on `STORY.md` | `refine-story/references/scorecard-rubric.md` | `refine-story` runs the rubric **and** its mode gate |
| Merge and split of stories | `backlog-item-types/story-sizing.md` | `refine-story` then optional checklist |
| Reject verb+file titles | `anti-task-shatter.md` | Checklist refuses to create a new US/TS per file |
| Who / Job / Outcome | `persona-context.md` (user stories only) | Refine feature mode |
| At most five implementation groups | mental check against checklist limits | `split-story-checklist` writes the file |

O1 does not ask “feature, tech, or split?”. That question belongs only to a direct `/refine-story`.

## When these skills are invoked

| Situation | Skill |
|-----------|--------|
| Product person shaping one bug, user story, or technical story, no feature delivery | `/refine-story` |
| That item needs a dependency checklist | `/split-story-checklist` |
| O2 stopped because clarification **B** or **I** is still open | `/refine-story` (and/or return to O1). Do not write PRD/PLAN until READY |
| O1 intent classified the input as one informal item or an idea | Early handoff to `/refine-story`, then re-enter O1 only if the result is multi-story or needs specialists |
| Normal feature through analyze → deliver → develop | Neither skill is required |

Readiness: no open **B** or **I**. **MINOR** may remain. Ready for a spec is not the same as a PLAN step being complete, and it is not `step_confirmed`.

## `refine-story`

Trigger: `/refine-story`.

**Mode is mandatory.** If the invoke does not name one, the skill stops and asks. It does not assume feature.

| Mode | Invoke | Default item |
|------|--------|----------------|
| feature | `feature`, `1` | User story or bug |
| tech | `tech`, `technical`, `2` | Technical story |
| split | `split`, `3` | Any type, then checklist handoff |

Only the chosen mode playbook is loaded.

Outcome: structured markdown (BDD acceptance and implementation steps) and a quality scorecard. Persistence, in order:

1. `features/NNN-slug/USnn/STORY.md` or `TSnn/STORY.md`, optional `REFINE/` beside it (including `REFINE/qa-history.md`)
2. Shortcut `docs/backlog/<slug>.md` in the target repo, after a documentation-language question

The skill does not create tracker cards. It does not invent architecture that belongs to O1 specialists.

Process: confirm the repo (and look for PRDs under `features/**/PRD/`, not a root `PRD/` folder); lock the mode; collect and generate inside that playbook; score product depth and acceptance budget; keep an interaction envelope at `NEEDS_CLARIFICATION` until READY; challenge vague BDD; persist only after the language question when using `docs/backlog/`.

While **B** or **I** remain, do not hand off to `sdd-spec`.

```text
/split-story-checklist - features/004-export/US01/STORY.md
/orchestrate-analyze - features/004-export
/sdd-spec - features/004-export/US01/STORY.md
```

## `split-story-checklist`

Trigger: `/split-story-checklist`, or refine mode `split`.

Input must already contain structured **Steps** (or a bug’s suggested fix). No steps: stop and return to `/refine-story`.

The checklist is SMART tasks under the **existing** story. It does not create new `USnn` or `TSnn` folders. Type (Bug, User Story, Technical Story) is written only on `STORY.md`.

If feature complexity is `trivial`, do not write a tasks file just to satisfy a gate. `medium` and `complex` need the checklist before handoff.

Language for the tasks file is asked once (**pt-BR** or **English**) before write.

Persistence:

1. `features/NNN-slug/USnn/REFINE/tasks.md` (default)
2. Flat `TASKS.md` beside the story only when the operator asks
3. Shortcut `docs/implementation-tasks/<slug>.md`

At most five implementation groups. Dependencies declared on steps win; otherwise layer or repo heuristics. Steps with no edge between them are marked parallel-safe. Tests sit in their own groups.

Handoff: multi-story returns to `/orchestrate-analyze`; one story with a spec path goes `/sdd-spec`; an existing PLAN goes `/sdd-develop` on step 1; a small code-only change goes `/developer` or a stack skill.
