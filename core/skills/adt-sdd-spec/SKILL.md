---
name: adt-sdd-spec
description: Create or revise a behavior-focused PRD under features/. Drafting and saving are preparation; one complete PLAN approval precedes implementation.
---

# Skill: adt-sdd-spec

## Trigger

Use when the user requests `/adt-sdd-spec`, a specification, or a new feature/change PRD.

## Outcome and boundaries

Create or revise one useful PRD in the user chat language (unless artifact language is explicitly configured) under the canonical `features/NNN-slug/USnn/PRD/` path. Default the story to `US01` when none is specified. Global storage uses `sdd/<repo-id>/features/...` portable paths. The PRD describes behavior, acceptance, boundaries, relevant contracts, and material risks; it does not prescribe implementation code.

Drafting and saving the PRD are preparation. Do not request a separate content approval or write confirmation. The complete PLAN receives one explicit approval before implementation through the planning/development flow. This skill does not write a PLAN or application code.

## Shared contracts

- Read `_shared/skill-boilerplate.md`, `sdd-artifacts/PIPELINE.md`, `STORAGE.md`, and `INVOCATION-CONTEXTS.md` as relevant. Honor the user's authorized scope, current branch, path safety, privacy, and repository instructions.
- Consult cited or available FEATURE, STORY, REFINE, analysis, and Memory Bank context only when relevant. `CONTINUITY`, `CHANGE`, `TASKS`, and specialist folders are optional context; brownfield classification or `needs_*` flags alone do not require them.
- Ask a focused question only when missing information could materially change behavior, acceptance, scope, required access, or an implementation choice. Record the question or observed answer and the affected work in the PRD. Minor uncertainty does not block unrelated work.
- Distinguish observed facts, user decisions, and inference. Do not promote an inference or suggestion into approved scope.
- If O2 invokes this skill internally, O2 owns and displays the progress table. A direct invocation follows `LIVE-STAGE-TABLE.md` and owns one table. Do not create duplicate progress or approval tables.

## Process

1. Resolve the feature/story and canonical storage location. Do not read or write outside authorized roots. Reuse information already supplied; inspect only sources needed to understand the requested behavior and material technical impact.
2. Draft from `templates/sdd/PRD.md` and follow `references/template-usage.md`. Write observable acceptance in Given / When / Then and cover material functional and non-functional requirements, contracts, and failure or boundary cases. Use equivalent sections and criteria in existing PRDs.
3. For a brownfield change, describe relevant current behavior, intended change, and concrete risks in the PRD when useful. Cite only evidence actually inspected and mark evidence limits. Do not require or create a separate CHANGE file solely for this purpose.
4. Check the PRD substantively in this authoring pass. Trace each material behavior to its source, contract and observable acceptance, including applicable failures. Resolve contradictions with the decision owner and check only the affected content after a correction. Treat equivalent writing as editorial.
5. Save the PRD under its canonical feature/story folder. Preserve portable `## Related` links where useful; omit links to absent siblings and never create sidecars for navigation. Do not persist a second approval state or planning-ready token as authorization.
6. Hand off the PRD to `/adt-sdd-plan`. A material unresolved question should be named with its affected work and resolved before dependent planning or implementation. Do not automatically reopen the completed PRD in a second contestation cycle.

## External paths

When the user explicitly names an external read/write target, follow `CLASSIC-EXTERNAL-ACCESS.md` for portable aliases and the exact authorized operations. Never place physical roots or absolute paths in the PRD.

## Lazy references

Load only what the current task needs: `references/template-usage.md`, `filename-numbering.md`, `storage-gitignore.md`, `selective-retrieval.md`, `challenge-vagueness.md`, `req-tracking.md`, `product-docs-language.md`, `english-override.md`, `validate-prd.md`, or `validate-change.md`. Read `validate-prd.md` only for specifically requested diagnostics of the legacy PRD format.

## Must not

- Write outside the canonical feature PRD folder or authorized external path.
- Edit application/test code or create a PLAN in this skill.
- Require CONTINUITY, CHANGE, TASKS, Memory Bank refresh, an architecture mirror, or a fixed template structure.
- Add a PRD content-approval gate, write-confirmation gate, structural preflight gate, or post-write contestation gate.
- Treat a minor question or a missing optional field as a blocker for unrelated work.
- Put implementation code in the PRD, invent user decisions, or claim evidence that was not inspected.
- Dump an entire Memory Bank or full PRD into a handoff; cite portable paths and concise summaries.

## Handoff

`/adt-sdd-plan - <portable-prd-path-under-features>`
