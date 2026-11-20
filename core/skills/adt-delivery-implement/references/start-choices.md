# Implementation start

## Before anything
- Locate and select the exact plan per `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/STORAGE-FEATURE.md`. An absent selected plan blocks implementation.
- When the selected plan is an independent split plan, read the feature-root primary plan for shared decisions.
- Check that approval is still valid per `{{TOOLKIT_ROOT}}/skills/_shared/adt-delivery/PLAN-LIFECYCLE.md`. A material change requires amendment and renewed approval before affected work.
- Inspect the current branch, working tree, progress and evidence before resuming. Preserve unrelated changes.

## Choices asked from the operator (never inferred from silence)
- Branch: at EVERY implementation start, ask whether to use the current branch or create a new one, unless the operator already selected it for that start.
- If the current branch is `main`, `master` or `develop`: stop before changing code, say so, and propose `feature/<slug>`. Create it only after explicit confirmation (`guardrails.md`, "Working branch").
- New branch: agree the name and base; check for name collisions and working-tree conflicts; create it without discarding changes.
- Cadence (`step_by_step` or `continuous`) and adt-code-review mode (`single` or `multi-angle`): ask ONCE and reuse the recorded choices.
- Also obtain the base branch and the review focus that the `adt-code-review` skill asks for.
- Ask the branch, then the cadence and review mode that are not yet recorded, then the base and the focus, in one message and in that order. On an integration branch the branch confirmation comes first and the remaining choices follow once it is answered.
- Base and review focus are recorded with the other choices and reused on later starts; ask again only if the operator changes them or they are missing.
- Normalize answers: accept a clear affirmative or the localized option in the user's language, per `{{TOOLKIT_ROOT}}/skills/_shared/agents/QUESTIONS.md`.
- Record the choices and the observed branch in the plan's Operational record (Choices).

## Baseline
- At the start, record concise baseline metadata in the plan: branch and HEAD, plus the relevant preexisting staged and unstaged changes needed to tell delivery changes apart.
- Do not mutate Git state and do not create new infrastructure.
