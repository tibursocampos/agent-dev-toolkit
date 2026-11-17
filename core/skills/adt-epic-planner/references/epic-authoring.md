# EPIC authoring and persistence

## One durable artifact

The sole deliverable is a navigable `EPIC.md`. Start from [`../assets/EPIC.template.md`](../assets/EPIC.template.md), adapting it to the initiative rather than treating every heading as mandatory. Persist answers in their corresponding sections: outcome, context/actors, scope, feature briefs, decisions and affected content, evidence/references, open questions, and exclusions or deferrals. Decisions are an index, not a substitute for updating the content they change. Do not save a transcript or a separate feature handoff.

Use short stable headings, a table of contents for a substantial document, and feature anchors. Keep the artifact's discovery status `draft` or `refining`; do not imply feature delivery state.

## Location and Git ignore

Default location is `epics/EPIC-NNN-slug/EPIC.md` in the current repository, but preserve a single established or user-chosen EPIC layout instead of introducing a competing one. `epics/` is optional and is created only when saving an EPIC there; no bootstrap or storage-mode change is required.

When saving the first EPIC under repository-root `epics/`, ensure `/epics/` appears idempotently in the root `.gitignore`, preserving existing lines and files. Do not remove already tracked files. An explicit user request to version EPICs takes precedence; do not add/retain this ignore rule against that instruction. For a custom path outside a repository, do not modify a parent `.gitignore` arbitrarily. If storage conventions are uncertain or competing layouts exist, ask and record the choice.

Before creating or updating a target, inspect whether it already exists. On resume, preserve the existing EPIC and its IDs. If the intended path or EPIC number is occupied by a different artifact, choose an unused path/number or ask the user to resolve the collision. Never overwrite an existing EPIC silently.

## Stable identity

Give the EPIC an identifier and slug when useful (for example, `EPIC-001`). Assign stable feature IDs such as `feature001`; never reuse or renumber them. Use IDs in cross-references so titles may change safely. O1 feature numbering is independent. If the user later asks to reflect a split in the EPIC, mark the old feature ID as superseded and link the replacement IDs. An O1 split alone does not require changing this document.

## O1 integration

O1 remains independent and can start directly from a selected feature in an EPIC. When the user cites a path and feature ID, locate that section and selectively read only the shared outcome/context, the selected brief, and relevant dependencies/references within that EPIC. A separately opened or cited Markdown reference or dependency remains subject to the normal promotion rule. Preserve the source path and distinguish its evidence/provenance. Do not copy the entire EPIC into a handoff, promote it into `memory-bank/`, require `CONTINUITY`, or impose an EPIC prerequisite. Continue O1's normal questions, gates, specialist work, and artifact ownership. The EPIC is context, not an authority over O1 or a new O1 handoff mechanism.

## Finish and verify

Before reporting completion, read the saved file and check:

- every table-of-contents link targets a present heading;
- feature IDs are stable, unique, and used consistently;
- each dependency points to a known feature or is labeled external/uncertain;
- decisions are reflected in affected sections;
- material questions and assumptions retain their impact/provenance;
- the overall outcome and feature map agree;
- status remains a discovery draft/refinement state.

Report the portable path, any open questions, and the next useful action. A saved draft does not mean the initiative is approved, O1 has started, or delivery is complete.
