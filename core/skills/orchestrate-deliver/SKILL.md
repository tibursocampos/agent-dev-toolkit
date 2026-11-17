---
name: orchestrate-deliver
description: Prepare story PRDs and implementation PLANs for Orchestrated Delivery. One explicit approval of the complete listed PLAN set precedes implementation.
---

# Skill: orchestrate-deliver

## Trigger and outcome

Use after O1 or when the user requests O2 for an existing feature. Resolve the canonical feature root and prepare PRDs and executable PLANs for eligible stories. O2 does not implement application code.

Classic/O1/O2/O3 progress is persisted only in the canonical PLAN execution table. Existing CONTINUITY, CHANGE, and TASKS files may be read as optional context, but new work does not require them and no conversion or deletion is required. Memory Bank is optional context; do not create or refresh it as an O2 prerequisite.

## Shared contracts

- Read `_shared/skill-boilerplate.md`, `sdd-artifacts/PIPELINE.md`, `STORAGE.md`, and `LIVE-STAGE-TABLE.md` as relevant. Preserve authorization, scope, path safety, privacy, and the current branch.
- O2 owns one contextual progress table across stories and internal `sdd-spec` / `sdd-plan` calls. Internal skills do not render competing tables.
- Ask a material question only when its answer could change behavior, acceptance, scope, required access, or an implementation decision. Mark the affected story/branch; keep independent eligible stories moving. Minor questions do not block unrelated work.
- Prepare documents sequentially or in parallel according to dependencies and available specialists. Parallelism is for document preparation only; it does not authorize parallel implementation in O3.
- `sdd-spec` owns PRD content and `sdd-plan` owns PLAN content. Use their contracts rather than creating a second process in O2.

## Process

1. Resolve feature path and read the canonical FEATURE/STORY records that define the requested backlog. Consult existing sidecars or analysis only when they contain evidence relevant to the affected behavior. Brownfield classification alone does not require specialist folders, architecture mirrors, or a preflight.
2. Identify eligible stories and dependencies from their current canonical records. A material unresolved decision blocks only the work that depends on it.
3. Select a sequential or parallel document-preparation approach when that choice materially affects execution. In parallel, assign clear story ownership and respect story dependencies. If specialists are unavailable, continue sequentially in the parent.
4. For each eligible story, use `sdd-spec` to draft/review/save its PRD, then `sdd-plan` to prepare the executable PLAN. A checklist may be used when useful, but `TASKS` is never required. Do not request intermediate approval to write or revise documents. Resolve material questions before planning dependent work.
5. Review the resulting PRD/PLAN content substantively: requested outcomes, boundaries, dependencies, acceptance, concrete risks, and appropriate validation. Use existing evidence when relevant. Structural validators and cross-artifact tools may help diagnose concrete problems, but they are not authorization or release gates.
6. Present the complete set of implementation PLAN paths for one explicit approval before implementation. Approval may cover a clearly listed set of plans or be requested for individual plans; it never covers plans not presented. Do not ask again merely because a story or document phase changed.
7. After approval, hand off the listed PLAN paths to `orchestrate-develop` or direct `sdd-develop`. Preserve external evidence references and scope limits. Do not start implementation here.

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

List each approved portable PLAN path and choose `/orchestrate-develop - <portable-feature-path>` or direct `/sdd-develop - <portable-plan-path>` as the next owner.
