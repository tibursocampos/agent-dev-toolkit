# 03 — Backlog shape

Three skills can help shape a backlog item: `refine-story`, `requirement-review`, and `split-story-checklist`. O1 investigates proportionally and creates justified stories without requiring these skills. Standalone use is for someone who wants a separate review, refinement, or task decomposition.

## What O1 already does

| Rule | File loaded by O1 | Standalone skill |
|------|-------------------|------------------|
| Story sizing and splitting | `backlog-item-types/story-sizing.md` when relevant | Optional refinement/checklist |
| Merge and split of stories | `backlog-item-types/story-sizing.md` | `refine-story` then optional checklist |
| Reject verb+file titles | `anti-task-shatter.md` | Checklist refuses to create a new US/TS per file |
| Who / Job / Outcome | `persona-context.md` (user stories only) | Refine feature mode |
| Optional dependency breakdown | Use when it helps coordinate work | `split-story-checklist` can write the file |

O1 does not ask “feature, tech, or split?”. That question belongs only to a direct `/refine-story`.

## When these skills are invoked

| Situation | Skill |
|-----------|--------|
| Product person shaping one bug, user story, or technical story, no feature delivery | `/refine-story` |
| That item needs a dependency checklist | `/split-story-checklist` |
| A feature or story has open questions before SDD, or a technical story must be checked against the repository | `/requirement-review --feature` or `--tech` |
| A material question blocks a feature/story decision | `/refine-story` or return to the owning flow with the specific question |
| O1 intent classified the input as one informal item or an idea | Early handoff to `/refine-story`, then re-enter O1 only if the result is multi-story or needs specialists |
| Normal feature through analyze → deliver → develop | Neither skill is required |

Backlog skills may use their own readiness language. For Classic SDD and Orchestrated Delivery, only a material unanswered decision blocks affected work; minor questions remain visible and do not stop independent work. See [PIPELINE.md](../../core/skills/_shared/sdd-artifacts/PIPELINE.md).

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

Resolve questions before handoff only when they materially affect behavior, acceptance, scope, required access, or implementation. Keep unrelated work moving.

```text
/split-story-checklist - features/NNN-slug/US01/STORY.md
/orchestrate-analyze - features/NNN-slug
/sdd-spec - features/NNN-slug/US01/STORY.md
```

## `requirement-review`

Trigger: `/requirement-review`, or `requirement-review --feature` / `--tech`.

**Mode is mandatory and exactly one per run.** If the invoke names neither mode or both, the skill asks once and loads no playbook.

| Mode | Invoke | Checks |
|------|--------|--------|
| `--feature` | `--feature`, `feature`, `1` | Actor, flow, rules, error and permission cases, data ownership, states, rollout; acceptance criteria split into atoms (`CA-002.a`) |
| `--tech` | `--tech`, `tech`, `2` | Named contracts, endpoints, events, and data flows searched in the repository; API standards applied by reference; technical follow-ups for `sdd-spec` |

Outcome: a review report with `Status: READY` or `Status: NEEDS_CLARIFICATION`, open questions with severity (B, I, MINOR) and one decision owner each, and Q&A entries. Persistence: `features/NNN-slug/USnn/REFINE/requirement-review-<mode>.md` beside the story, with the Q&A history in `REFINE/qa-history.md`; shortcut `docs/backlog/<slug>-requirement-review-<mode>.md` when no story folder exists. Writes wait for the `confirm` id (pt-BR label: `sim`).

`refine-story` runs this review at step 4a before it hands off to `sdd-spec`: `--feature`, then `--tech` when the story touches a repository. Standalone use is the same.

The skill never writes code and never decides a product question by assumption.

## `split-story-checklist`

Trigger: `/split-story-checklist`, or refine mode `split`.

Input must already contain structured **Steps** (or a bug’s suggested fix), unless the caller is `sdd-plan` with `source=prd`. In that case the source is the closed story and PRD. No steps yet: build groups from the PRD `REQ` rows. Do not send the caller back to `/refine-story`.

The checklist is SMART tasks under the **existing** story. It does not create new `USnn` or `TSnn` folders. Type (Bug, User Story, Technical Story) is written only on `STORY.md`.

The checklist is optional for all complexity levels. `sdd-plan` derives executable steps directly from the PRD or sufficiently specified demand; a missing checklist never blocks handoff.

On a direct invoke, documentation language is asked once, in the chat language, before write. An orchestrated call uses the chat language and does not ask.

Persistence:

1. `features/NNN-slug/USnn/REFINE/tasks.md` (default)
2. Flat `TASKS.md` beside the story only when the operator asks
3. Shortcut `docs/implementation-tasks/<slug>.md`

At most five implementation groups. Dependencies declared on steps win; otherwise layer or repo heuristics. Steps with no edge between them are marked parallel-safe. Tests sit in their own groups.

Handoff: multi-story returns to `/orchestrate-analyze`; one story with a spec path goes `/sdd-spec`; an existing PLAN goes `/sdd-develop` on step 1; a small code-only change goes `/developer` or a stack skill.
