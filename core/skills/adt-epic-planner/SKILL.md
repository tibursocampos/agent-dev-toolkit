---
name: adt-epic-planner
description: Facilitate discovery and proportionate feature decomposition for a multi-feature initiative, then persist one navigable EPIC.md. Use when the user asks to structure an initiative or invokes $adt-epic-planner.
---

# Skill: adt-epic-planner

## STOP - Read before ANY tool call

Read `{{TOOLKIT_ROOT}}/skills/_shared/skill-boilerplate.md` first and follow its guardrails and session gates. Do not duplicate shared policies here.

## Trigger

Use when the user asks to plan or organize an initiative likely to span multiple features, or explicitly invokes `$adt-epic-planner`. This skill is optional; do not begin writing solely because a request sounds like a product initiative. If discovery shows one cohesive feature, explain that O1 or Classic SDD may be a better fit; the user may still keep an EPIC for useful context.

## Outcome and boundary

Conduct active discovery and create or refine one `EPIC.md` that captures the shared outcome, relevant context, scope, and feature briefs. It is a discovery draft, not an execution plan or delivery tracker. Do not create US/TS stories, PRDs, PLANs, `features/` directories, code, status tracking, or a separate handoff/brief. O1 remains usable without an EPIC and may revise a selected feature's cut without requiring EPIC reconciliation.

The EPIC is the durable record: incorporate answers and decisions into their relevant sections, not just a transcript or decision log. User and repository language determine the EPIC prose; this skill and its references remain en-US. Resolve content language using `{{TOOLKIT_ROOT}}/skills/_shared/agents/LANGUAGE.md` when available; otherwise mirror the session language. Keep IDs and paths in English.

## First operational step: session configuration

Before investigating the request or doing other substantive work, resolve effective `subagents` capability and read orchestration preferences when available. Follow the shared contract rather than duplicating it:

- If capability is `none`, `unknown`, or unavailable, skip model-choice contracts and do not ask a model/effort question. Continue without agents, using the bounded in-parent or manual fallback that applies.
- If capability is `native`, load `{{TOOLKIT_ROOT}}/skills/_shared/agents/SPAWN-DIGEST.md`, then the full `SPAWN.md` and required model/option/question contracts it names. Ask the one-time per-session configuration question, using currently supported choices only. Default is inheritance; never hardcode model names or preferences. Do no substantive discovery or delegation while the answer is pending. Do not repeat a valid session answer.

Only after this setup, proceed with the workflow. The main agent owns discovery conversation, questions, synthesis, and EPIC persistence. Delegate only specialist work justified by shared contracts and evidence. Apply `always` and `adaptive` rules from `SPAWN.md`; in `adaptive`, keep work in-parent only when it meets the shared limits and has no exclusion. Reuse roles in `ROSTER.md`; do not invent an EPIC specialist. When native agents are unavailable, do useful bounded analysis in-parent where permitted or provide a manual handoff; absence of agents is not a blocker.

## Workflow

1. Read [discovery and grounding](references/discovery-and-grounding.md). Identify the initiative, target repository/service and existing EPIC or other cited context. Confirm a destination only when there are multiple reasonable choices.
2. Investigate selectively and report material observations, contradictions, inferences, and gaps. Ask focused questions that can change the outcome, scope, risk, or ordering. Do not impose a fixed question or feature count.
3. Read [decomposition](references/decomposition.md). Shape features around recognizable outcomes or capabilities, with real dependencies and proportional detail.
4. Read [EPIC authoring and persistence](references/epic-authoring.md). Draft or update the single EPIC, preserve stable IDs, and apply the chosen storage behavior.
5. Re-read the saved artifact. Check navigation, decisions reflected in affected content, feature references/dependencies, unresolved questions, and draft status. Report the path and next useful action. A saved draft is not approval, O1 readiness, or delivery completion.

## Handoff

When the user wants to continue with one feature, invoke `adt-orchestrate-analyze` with the EPIC path and selected stable feature ID. O1 uses that brief and relevant shared context as optional input; do not require this handoff to save the EPIC or continue using O1 without one.

## Lazy-load

| When | Path |
|---|---|
| Session configuration/delegation | `{{TOOLKIT_ROOT}}/skills/_shared/agents/{SPAWN-DIGEST,SPAWN,SUBAGENT-MODEL,SUBAGENT-OPTIONS,QUESTIONS,ROSTER,RECEIPT}.md` as applicable |
| Content-language resolution | `{{TOOLKIT_ROOT}}/skills/_shared/agents/LANGUAGE.md` |
| Selective retrieval | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/SELECTIVE-RETRIEVAL.md` |
| Starting artifact | `assets/EPIC.template.md` |

**Never by default:** Do not preload every file under `references/`, a whole repository, the memory bank, or an entire cited document. Load only the section needed for the current step.

Never load a shared contract just to restate it here. Read only the relevant files and sections. Do not dump a whole repository, memory bank, or cited document into a prompt or handoff.
