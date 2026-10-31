# Choosing the flow

This guide helps you choose which toolkit flow to use before you start: Orchestrated Delivery, Classic SDD, backlog refinement, or requirement review. The choice sets the entry skill and the artifacts that will be written. The details of each flow are in the guides linked from the table.

## Decision tree

```mermaid
flowchart TD
  Start([New work]) --> Q{What is the situation?}
  Q -->|Feature with several stories, brownfield, or specialists| ORCH["orchestrate-analyze → orchestrate-deliver → orchestrate-develop or sdd-develop"]
  Q -->|One story already clear, no specialists| SDD["sdd-spec → sdd-plan → sdd-develop"]
  Q -->|Informal product item| REF["refine-story → split-story-checklist"]
  Q -->|Requirement must be challenged before SDD| REV["requirement-review --feature or --tech"]
  REF --> SDD
  REV --> SDD
  ORCH --> Done([Code, tests and commit])
  SDD --> Done
```

The flows are not prerequisites for one another. Classic SDD can start directly, without `orchestrate-analyze`. Suggest the orchestrated path only when there are several stories, brownfield complexity, or specialist folders.

## Flow table

| Flow | When to use | Entry point | Guide or doc |
|------|-------------|-------------|--------------|
| Orchestrated Delivery | Feature with several stories, brownfield, or that needs specialists | `/orchestrate-analyze` | [../sessions/01-orchestrated-delivery.md](../sessions/01-orchestrated-delivery.md) |
| Classic SDD | One story already clear, no need for specialists | `/sdd-spec` | [../sessions/02-classic-sdd.md](../sessions/02-classic-sdd.md) |
| Refine backlog item | Informal product item (bug, user story, or technical story) before SDD | `/refine-story` | [backlog-refine.md](backlog-refine.md) and [../sessions/03-backlog-shape.md](../sessions/03-backlog-shape.md) |
| Review requirement | Check acceptance criteria or contracts before SDD | `/requirement-review --feature` or `--tech` | [../sessions/03-backlog-shape.md](../sessions/03-backlog-shape.md) |

For a trivial single file, use `/developer` or the stack skill, if the operator chooses that shortcut.

## Readiness rule

An open **B** (blocker), **I** (important), or **MINOR** item keeps the status at `NEEDS_CLARIFICATION`. Only `READY` releases the write of the next artifact (PRD, PLAN, or story). This rule applies at every gate, including MINOR. Source: [readiness-severity.md](../../core/skills/_shared/sdd-artifacts/readiness-severity.md).

## Write limits

- Canonical PRD and PLAN paths live under `features/NNN-slug/`. Do not create artifacts outside the `features/` tree.
- Without a `features/NNN-slug/` folder, `sdd-spec` does not read `docs/backlog/` on its own. A `.md` from `docs/backlog/` is used only when the operator cites its path (promote in `direct` mode, see [PIPELINE.md](../../core/skills/_shared/sdd-artifacts/PIPELINE.md)) or when the content is pasted into the chat.
- `docs/backlog/` is a write shortcut for `refine-story`, `requirement-review`, and `split-story-checklist`. It is not a canonical source for PRD or PLAN.

## Sessions and gates

- `sdd-spec` writes only the PRD in this session. `sdd-plan` writes only the PLAN.
- `sdd-develop` executes **one** PLAN step per session. When it finishes, stop. The next step starts in another session.
- Before any new artifact is written, the skill shows the path and a summary and asks a gate question. Writing happens only after the `confirm` answer. Silence, an ambiguous or unrelated reply, or an emoji alone is not an answer; the question stays pending.

### Gate legend

Labels are shown in the user's conversation language. The id is stable and is what the rule matches. Answers are matched by meaning, not by a fixed word. Contract: `core/skills/_shared/agents/QUESTIONS.md`.

| Id | Label (pt-BR) | Meaning |
|----|---------------|---------|
| `confirm` | sim | Approve the exact action or artifact shown. |
| `adjust` | ajustar | Change the proposal before acting. |
| `cancel` | cancelar | Stop. Do not perform the gated action. |
| `skip` | pular | Leave an optional step undone and continue. |
| `decline` | não | Refuse an optional offer. |
