---
name: adt-orchestrate-prepare
description: Prepare story PRDs and implementation PLANs for Orchestrated Delivery. One explicit approval of the complete listed PLAN set precedes implementation.
---

# Skill: adt-orchestrate-prepare

## Trigger and outcome

Use after O1 or when the user requests O2 for an existing feature. Resolve the canonical feature root and prepare PRDs and executable PLANs for eligible stories. O2 does not implement application code.

Classic/O1/O2/O3 progress is persisted only in the canonical PLAN execution table. Existing CONTINUITY, CHANGE, and TASKS files may be read as optional context, but new work does not require them and no conversion or deletion is required. Memory Bank is optional context; do not create or refresh it as an O2 prerequisite.

## Shared contracts

- Read `_shared/skill-boilerplate.md`, `sdd-artifacts/PIPELINE.md`, `STORAGE.md`, and `LIVE-STAGE-TABLE.md` as relevant. Preserve authorization, scope, path safety, privacy, and the current branch.
- O2 owns one contextual progress table across stories and internal `adt-sdd-spec` / `adt-sdd-plan` calls. Internal skills do not render competing tables.
- Ask a material question only when its answer could change behavior, acceptance, scope, required access, or an implementation decision. Record the question or confirmed answer and identify the affected story/branch. Keep independent eligible stories moving.
- Prepare documents sequentially or in parallel according to dependencies and available specialists. Parallelism is for document preparation only; it does not authorize parallel implementation in O3.
- `adt-sdd-spec` owns PRD content and `adt-sdd-plan` owns PLAN content. Use their contracts rather than creating a second process in O2.

## Process

1. Resolve feature path and read the canonical FEATURE/STORY records that define the requested backlog. Consult existing sidecars or analysis only when they contain evidence relevant to the affected behavior. Brownfield classification alone does not require specialist folders, architecture mirrors, or a preflight.
2. Identify eligible stories and dependencies from their current canonical records. A material unresolved decision blocks only the work that depends on it.
3. Select a sequential or parallel document-preparation approach when that choice materially affects execution. In parallel, assign clear story ownership and respect story dependencies. If specialists are unavailable, continue sequentially in the parent.
4. For each eligible story, use `adt-sdd-spec` to draft/review/save its PRD, then `adt-sdd-plan` to prepare the executable PLAN. Follow `references/per-story-contracts.md` for initial authoring and material revisions. A checklist is optional. Resolve material questions before planning dependent work.
5. Reconcile the resulting PRD/PLAN set once for outcomes, interfaces between stories, dependencies, acceptance, risks and validation. Reuse relevant evidence and check only affected content after a correction. Equivalent document wording is an editorial concern.
6. Present the complete eligible set of implementation PLAN paths for one explicit approval before implementation. State the approved scope and leave dependent stories outside that set until their material blockers are resolved. Editorial corrections preserve approval; revisit only the affected scope after a material change.
7. After approval, hand off the listed PLAN paths to `adt-orchestrate-implement` or direct `adt-sdd-develop`. Preserve external evidence references and scope limits. Do not start implementation here.

## Resume

On resume, trust current FEATURE/STORY/PRD/PLAN content first. Consult old CONTINUITY/CHANGE/TASKS only to resolve relevant context. If records materially conflict and available evidence cannot establish the current state, present that specific conflict and pause the affected work; do not require full conversion or infer completion from a file's presence.

## Must not

- Write application or test code, implement PLAN steps, or authorize work outside the approved scope.
- Require a Memory Bank gate, backlog approval checkpoint, CONTINUITY, CHANGE, TASKS, fixed-format validator, preflight, or per-document/per-story approval.
- Block on headings, numbering, language, punctuation, or optional fields when the substantive behavior and acceptance are clear.
- Stop independent eligible stories because another story is blocked.
- Render a progress table from an internal spec/plan call or duplicate O2 progress in a checkpoint table.
- Treat approval of one plan as approval of unlisted plans.

## Handoff

List each approved portable PLAN path and choose `/adt-orchestrate-implement - <portable-feature-path>` or direct `/adt-sdd-develop - <portable-plan-path>` as the next owner.
