# Live progress tables

Chat-only progress tables for every flow: O1, O2, O3, `sdd-spec`, `sdd-plan`, `sdd-develop` and Backlog Refine. Skill prose in this file is English. Render tables in the user chat language (`LANGUAGE.md`) using the label map below.

This file defines the standard once. Flow `SKILL.md` files point here and must not hard-code column names, state labels, or glyphs.

Do not write any table from this file into `PLAN.md`, `FEATURE.md`, `CONTINUITY.md`, or `STORY.md`. They are chat projections. The one persisted table is the PLAN `Implementation progress` ledger, which is separate.

## 1. Fixed structure

### State keys

Internal state keys stay English. Validators and `Invoke-O3ArtifactPreflight.ps1` use only these keys. Only the displayed label changes with language.

| Key | Glyph |
|-----|-------|
| `pending` | `[ ]` |
| `in_progress` | `[~]` |
| `completed` | `[x]` |
| `blocked` | `[!]` |
| `skipped` | `[-]` |

Glyphs are ASCII and identical in every language. Do not use any other glyph or a second state vocabulary. `skipped` requires a reason in the evidence column. `blocked` names the cause and the owner. Do not imply success for `blocked` or `skipped`.

The PLAN file keeps its canonical uppercase status tokens (`PENDING`, `IN_PROGRESS`, `COMPLETED`, `BLOCKED`, `SKIPPED`); they map one to one to the keys above.

### Column order per table kind

Column order is fixed. Only the header text is localized.

| Kind | Columns, in order |
|------|-------------------|
| Stage table | `stage`, `status`, `weight`, `what_happened` |
| PLAN-step table | `step_id`, `step`, `dependencies`, `status`, `evidence`, `next_action` |
| Closeout table | `gate`, `status`, `owner`, `evidence` |

Flows with their own list (open questions, groups) use the column order given in their caller section and the same state keys.

## 2. Label map

Displayed headers and state labels follow the user chat language (`LANGUAGE.md`). Look labels up here; never invent per-flow wording. For a language not listed, translate each entry consistently and keep the key and glyph unchanged.

| Key | pt-BR | English |
|-----|-------|---------|
| `stage` | Etapa | Stage |
| `status` | Estado | Status |
| `weight` | Peso de análise | Analysis weight |
| `what_happened` | O que aconteceu | What happened |
| `step_id` | ID do passo | Step ID |
| `step` | Passo | Step |
| `dependencies` | Dependências | Dependencies |
| `evidence` | Evidência | Evidence |
| `next_action` | Próxima ação / responsável | Next action / owner |
| `gate` | Gate | Gate |
| `owner` | Responsável | Owner |
| `group` | Grupo | Group |
| `wave` | Onda | Wave |
| `question` | Pergunta | Question |
| `criterion` | Critério | Criterion |
| `pending` | `[ ]` pendente | `[ ]` pending |
| `in_progress` | `[~]` em andamento | `[~]` in progress |
| `completed` | `[x]` concluído | `[x]` completed |
| `blocked` | `[!]` bloqueado | `[!]` blocked |
| `skipped` | `[-]` ignorado | `[-]` skipped |

Weight tokens are qualitative and stay as written below in every language: `Low`, `Medium`, `High`, `Very high`, or `—`. Weight is never elapsed time, a duration promise, or story points.

`What happened` / `evidence` names actions, artifacts, evidence paths, and blockers. Do not narrate hidden reasoning.

## 3. Display points

Every flow that has a table MUST render it at each of these named points. This is a requirement, not "when useful".

1. **Start**: when the stage or flow starts, before the first row runs (first row `in_progress`, the rest `pending`).
2. **Before gate**: before each gate, that is, before each question to the operator.
3. **After gate answer**: after the operator answers each gate.
4. **Row change**: on each row state change.
5. **Blocker or failure**: when a blocker or failure becomes observable. Stop the redraw at the `blocked` state; do not present a successful table or imply a dependent spawn is authorized.
6. **Close**: at close or handoff.

When the host provides no intermediate event, keep the last verifiable table until control returns. Do not invent streaming, heartbeat cadence, or retrospective progress.

## 4. Completeness

Always render the full table with every row. It is forbidden to summarize consecutive rows (for example "S3-S7"), show only the changed row, or omit completed rows. Completed rows stay as evidence.

A child return never replaces the owning flow's table. The parent re-reads the canonical state, reconciles it with the receipt, and then renders the owning flow's complete table (`SPAWN.md`). A child-rendered table or a prose summary is not the flow table.

## 5. One table per moment

- Do not show a second form of the same table, or two different progress tables, in the same turn.
- The closeout table appears only when the operator asks to close the wave.
- The weighted stage table defined in the next section is for O1, O2, `sdd-plan`, and `sdd-spec`. It is **not** shown in chat for development flows (direct `sdd-develop` and O3). Those flows use the PLAN-step table, and the closeout table when close is requested. `sdd-develop` and `orchestrate-develop` do not emit a `Develop:` heartbeat.
- Direct `sdd-develop` also follows `sdd-develop/references/execution-display.md`.

## Weighted stage table (O1, O2, sdd-spec, sdd-plan only)

Columns: `stage`, `status`, `weight`, `what_happened`.

Before the first row runs, mark that row `in_progress` and the rest `pending`. After each row finishes, redraw the entire table: completed rows become `completed`, the next row becomes `in_progress`, and `what_happened` states the action or the evidence path. Use `blocked` or `skipped` when the row stops.

If receipt validation is missing, incomplete, inconsistent, blocked, or failed, stop the redraw at the blocked state and do not present a successful final table or imply that a dependent spawn is authorized.

## Cumulative O1/O2 checkpoint (chat-only)

During O1 and O2, pair the stage table with a cumulative checkpoint in the operator chat. It is a concise projection of evidence already gathered and canonical artifacts already written; it is not a new persisted status source. Render it at the display points above, at each story-cycle boundary, and at handoff or close. When continuing later, rebuild it from current artifacts and the conversation's confirmed decisions.

Use this table shape in the operator's chat language:

| Campo | Estado acumulado |
|-------|-------------------|
| Processo atual | Fase, etapa/story e gate em andamento |
| Concluído | Marcos concluídos com evidência ou caminho do artefato |
| Pendente | Próximos marcos, artefatos ou gates ainda necessários |
| Decisões / questões | Decisões confirmadas e questões abertas; escrever `nenhuma` quando não houver |
| Bloqueios | Causa, escopo afetado e gate/owner responsável; escrever `nenhum` quando não houver |
| Próxima ação | Ação concreta e responsável/gate seguinte |

Keep entries cumulative across the current O1/O2 run: a new checkpoint adds the latest verified state without dropping still-relevant completed work, pending work, decisions, or blockers. Cite the owning FEATURE/STORY/ANALYSIS/ARCH/SEC/PRD/PLAN/CONTINUITY path or decision id instead of copying its full content. Mark unverified status as unknown or a gap; do not infer completion from a created file or from elapsed conversation. Do not turn a technical gap into a product question. The checkpoint is chat-only: do not copy it into CONTINUITY, FEATURE, PRD, PLAN, or the O3 step table.

For example, a later checkpoint after a decision gate retains still-open inspection from the earlier checkpoint:

| Campo | Estado acumulado |
|-------|-------------------|
| Processo atual | O2, US01, revisão do PLAN |
| Concluído | O1 trace registrado em `ANALYSIS/`; decisão D-01 confirmada |
| Pendente | Validar dependências do PLAN e aprovação desta história |
| Decisões / questões | D-01 confirmada; questão Q-02 segue aberta |
| Bloqueios | Q-02 bloqueia somente US01 |
| Próxima ação | Retomar análise dirigida de Q-02; owner: O2 |

This is illustrative only. In a real checkpoint, preserve the actual unresolved items and cite their canonical owner.

## 6. Caller sections

Each caller uses the column order of its kind and a `status` column with the state keys above. Row lists below are exact; a flow adds no row and drops none. Flow `SKILL.md` files cite their section here.

### orchestrate-analyze (O1) step 8c

Weighted stage table.

| Stage | Weight |
|-------|--------|
| Read FEATURE and memory-bank | Medium |
| Specialists per `needs_*` | Very high |
| First findings pass | High |
| Second isolated pass | High |
| Close findings that have evidence | Medium |
| One question batch | Low |

Stop redraw when `open_question` fires. The blocked row is `blocked`. Do not continue to story folders.

### orchestrate-deliver (O2)

Weighted stage table, rendered for the full O2 run beginning before the first stage executes. For série mode, repeat the story-cycle rows for each eligible US/TS in canonical dependency/order sequence; label each row with its story ID. Mark conditional checklist work `completed` with the evidence that it was required and run, or `skipped` with the reason that the feature is `trivial` and the checklist is not applicable. The table is never written into `CONTINUITY.md`.

| Stage | Weight |
|-------|--------|
| Resolve memory-bank and feature context | Medium |
| Reconcile canonical roster, required siblings, dependencies, and readiness | High |
| Choose execution mode and build eligible queue | Low |
| Per story: read STORY, required siblings, and relevant context | High |
| Per story: sdd-spec, PRD contestation, and readiness | High |
| Per story: checklist when required | Medium |
| Per story: sdd-plan and plan validation | High |
| Per story: present and process the applicable approval gate | Medium |
| Per story: reconcile checkpoint and recompute next eligible story | Medium |
| Cross-artifact analysis and PRD→PLAN→CHANGE preflight | High |
| Emit final multi-path handoff | Low |

The per-story approval table has one row per story and is redrawn in full at every gate (`gate`, `status`, `owner`, `evidence` columns; the story ID is the gate cell).

In série mode, completing one story does not end O2. Reconcile `CONTINUITY.md` against canonical `FEATURE.md`, `STORY.md`, PRD/PLAN, required siblings, and dependencies; then read the next eligible US/TS context and continue its full O2 cycle. Do not ask an extra continue question. Stop only at a material blocker, a decision or approval gate that is due, or when every story is closed. Each story retains its own write and approval gates. `sdd-develop`'s one-step stop does not govern the O2 story queue.

### sdd-spec

Weighted stage table.

| Stage | Weight |
|-------|--------|
| Resolve workspace and requirements | Medium |
| Explore the repo | High |
| Clarify (question blocks) | Medium |
| Draft | High |
| Review | High |
| Content gate | Low |
| Preview | Low |
| Write gate | Low |
| Persist | Low |

Do not save this table in the PRD.

### sdd-plan

Weighted stage table. Rows match the `sdd-plan/SKILL.md` steps.

| Stage | Weight |
|-------|--------|
| Resolve PRD | Medium |
| Explore the repo | Very high |
| Draft | High |
| Review 1 | High |
| Review 2 | High |
| Content gate | Low |
| Preview | Low |
| Write gate | Low |
| Persist | Low |

Do not save this table in the PLAN.

### orchestrate-develop (O3) and sdd-develop (direct): PLAN-step table

Used by O3 and by direct `sdd-develop` (any pacing mode). It is a read-only projection of the approved PLAN's `Implementation progress` rows. Columns: `step_id`, `step`, `dependencies`, `status`, `evidence`, `next_action`.

Render exactly one row for every PLAN step, including consecutive steps such as S3–S7. Never combine multiple steps into a summary row. Use the PLAN status token mapped to the state keys; localize headers and remaining text. Keep the five states distinct. Do not infer completion from a receipt without its persisted, reconciled checkpoint. The pending-only dispatch queue is separate and must never provide the displayed row set. Every user-facing status summary and transition includes the complete table, even when dispatch is blocked, no step is eligible, or the workflow stops. Start from the re-read PLAN and overlay only validated receipt, checkpoint, session, or claim state. For O3, use `Invoke-O3ArtifactPreflight.ps1 -EmitStepTable` for the canonical PLAN projection; provide a complete `-StepStateOverridesPath` projection when validated operational state differs. The formatter rejects missing, duplicate, extra, and invalid step-state rows.

Render the complete table at flow start (before the first spawn for O3). After each child return, validate its receipt, read and reconcile the persisted PLAN checkpoint, then redraw the complete table before evaluating the next spawn. Redraw when a blocker, failure, or other advancement gate becomes observable. The table at step close serves as the operator-facing step ledger; do not add a raw ledger dump or the weighted stage table. O3 closeout activities are tracked separately from PLAN-step rows.

### Closeout table (O3 wave close)

Shown only when the operator requests wave close. Do not add closeout activities as PLAN steps or combine them with the PLAN-step table. Columns: `gate`, `status`, `owner`, `evidence`.

Include each applicable gate in the order defined by `orchestrate-develop/SKILL.md`: `run-tests`, `code-review`, review corrections when findings require changes, post-review `run-tests` when changes require it (otherwise `skipped` with the no-rerun reason), security review, and any applicable build or operator-requested commit/push handoff. Do not imply that optional or not-yet-requested gates have run.

`skipped` requires a reason and evidence that the gate is not required. `completed` requires current evidence for the gate. `blocked` names the owner and next action.

Render the applicable rows when closeout begins and update them after each observable gate result and after later changes that affect gate evidence. Associate each result with the reviewed/tested revision or changed scope when available. When a later change invalidates evidence, return only affected rows to `pending`, preserve unaffected evidence, identify the superseded evidence and next action, and do not advance past required gates with stale evidence. This table is a chat-only projection; it does not create persistent closeout state in `PLAN.md` or `CONTINUITY.md`.

### requirement-review: open questions

Columns: `question`, `status`, `evidence` (source or owner of the answer). One row per question. Resolved items stay in the Q&A history, not in the table once closed by the operator; `pending` and `blocked` questions always appear. Render the full table at every stop and at close.

### refine-story (feature, tech, split): stage table

Columns: `stage`, `status`, `what_happened`.

| Stage |
|-------|
| Workspace and mode |
| Mode playbook (feature, tech, or split) |
| Clarify (question blocks) |
| Quality scorecard |
| Requirement review |
| Envelope status refresh |
| Validation |
| Persistence (when requested) |
| Handoff |

At close, also render the scorecard with every criterion (`criterion`, `status`, `evidence`), in all three modes.

### split-story-checklist: groups

Columns: `group`, `step_ids` (Steps), `wave`, `status`. One row per group, rendered in chat when the checklist is summarized and at every redraw point of section 3. Never collapse groups.
