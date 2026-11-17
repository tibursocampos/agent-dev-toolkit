# Refining backlog items

This guide describes the backlog refinement flow: how an informal product item becomes a story ready for SDD, which skills take part, and where each one writes.

## Flow

1. `refine-story` can shape the item into `STORY.md` with useful acceptance detail.
2. In step 4a, `refine-story` calls `requirement-review` before the handoff. `requirement-review` challenges the item, asks the open questions, and writes only after a `confirm` answer.
3. `split-story-checklist` can break the story into a dependency-aware task checklist when that separate artifact is useful.
4. `sdd-plan` derives executable steps directly from the PRD. It may use the independent checklist skill, but missing `REFINE/tasks.md` or `TASKS.md` never blocks planning at any complexity level.

`orchestrate-analyze` also uses the feature research of `refine-story` internally, in step 8c. For that reason, the orchestrated path does not need `refine-story` to be called beforehand.

Resolve a question before dependent work only when it materially affects behavior, acceptance, scope, access, or implementation. Keep minor questions visible and allow unrelated work to continue.

## Where it writes

| Artifact | Path with a story | Path without a story (shortcut) |
|----------|-------------------|----------------------------------|
| Story | `features/NNN-slug/USnn/STORY.md` (or `TSnn`) | `docs/backlog/<slug>.md` |
| Requirement review | `features/NNN-slug/USnn/REFINE/requirement-review-feature.md` (or `-tech.md`) | `docs/backlog/<slug>-requirement-review-<mode>.md` |
| Q&A history | `features/NNN-slug/USnn/REFINE/qa-history.md` | `docs/backlog/<slug>-qa-history.md` |
| Optional task checklist | `features/NNN-slug/USnn/REFINE/tasks.md` | `docs/implementation-tasks/<slug>.md` |

With text pasted into the chat and no file path, the report stays in the chat. Each standalone skill follows its own persistence and confirmation contract; SDD draft writing is preparation and has no separate write approval.

## Skills

### refine-story

- **Reads:** the path or text the operator provides. It looks for PRDs under `features/**/PRD/`, not a `PRD/` folder at the root.
- **Writes:** `STORY.md` (or `TSnn/STORY.md`) and `REFINE/qa-history.md`. Shortcut: `docs/backlog/<slug>.md`, after a question about the document language.
- **Where:** [core/skills/refine-story/SKILL.md](../../core/skills/refine-story/SKILL.md).
- **When to use:** a product item (bug, user story, or technical story) that is not yet a full feature delivery. The mode is mandatory: `feature`, `tech`, or `split`. Without a mode, the skill asks.

### requirement-review

- **Reads:** `STORY.md`, `FEATURE.md`, `REFINE/refine.md` beside the story, or pasted text. Before asking, it reads `REFINE/qa-history.md` so it does not repeat a resolved question. In `--tech` mode, it also reads the repository.
- **Writes:** the review report and the Q&A history, after a `confirm` answer. Without a story folder, the report stays in the chat, unless the operator names a story folder or the `docs/backlog/` shortcut.
- **Where:** [core/skills/requirement-review/SKILL.md](../../core/skills/requirement-review/SKILL.md).
- **When to use:** check acceptance criteria (`--feature`) or contracts and flows in the code (`--tech`) before SDD. Exactly one mode per run. Without a mode, the skill asks.

### split-story-checklist

- **Reads:** `STORY.md` with the **Steps** section filled in (or the **Suggested fix** for a bug). When called by `sdd-plan`, it reads the PRD and the story's `REQ` rows.
- **Writes:** `REFINE/tasks.md` when a checklist is requested or useful. It updates that file if it already exists and does not create a duplicate `TASKS.md`. Shortcut: `docs/implementation-tasks/<slug>.md`. It does not create new `USnn` or `TSnn` folders.
- **Where:** [core/skills/split-story-checklist/SKILL.md](../../core/skills/split-story-checklist/SKILL.md).
- **When to use:** when the operator requests a checklist or decomposition would help coordination. It is optional for every complexity level and is not a prerequisite to `sdd-plan`.

## See also

- [flow-selection.md](flow-selection.md): choosing the flow.
- [../sessions/03-backlog-shape.md](../sessions/03-backlog-shape.md): scorecard and story rules inside analysis.
- [../sessions/01-orchestrated-delivery.md](../sessions/01-orchestrated-delivery.md): the full feature path.
