# Subagent model policy (Orchestrated Delivery)

Contract for **LLM model** on native subagent spawns (`Agent` calls) from `orchestrate-analyze`, `orchestrate-deliver`, `orchestrate-develop`, and other parent spawns under `SPAWN.md`. Orthogonal to **when** to spawn (`ROSTER.md`), **native vs fallback** (`SPAWN.md` + `orchestrator-session` policy), and to Memory Bank Gate policy `auto` (bank health — not a host auto model).

Install path after sync: `{{TOOLKIT_ROOT}}/skills/_shared/agents/SUBAGENT-MODEL.md`

## Invocation axes (A ≠ B ≠ C)

Normative split — do **not** conflate axes. Marker: `A≠B≠C`.

| Axis | Owns | Rule |
|------|------|------|
| **A** | `SPAWN.md` | Spawn vs in-parent (thin-trivial in-parent preserved). **This file does not decide spawn.** |
| **B** | This file | Default: **omit `model`** → child **inherits** the parent session model (RN02). |
| **C** | This file | No alternate pair except the single session choice (answered question or explicit request). Silence ≠ approval. |

Cross-PLAN: every spawn omits `model` and `effort` unless the session choice selected a verified pair. Pinning child model ≠ parent by default is forbidden (FEATURE non-goal / RN02).

## Default (almost every spawn)

1. Call `Agent` **without** the `model` and `effort` parameters.
2. Child uses the **same model as the parent session** (whatever the user selected for this chat).
3. Do **not** ask about model choice per spawn; the one session question below is the only model question.
4. Do **not** pick a model or effort on your own.
5. If Caveman is ON: require end-of-pass **receipt** per `RECEIPT.md`; inherit parent intensity; keep gates/drafts clear (Auto-Clarity). Child I/O remains Caveman-scoped per `SPAWN.md`.

## Session choice (once per session)

The parent asks one initial question about the subagents' session configuration, **once per session**. That answer selects inheritance, reuse of an eligible saved pair, or the new-model branch, and applies to every subagent in the session. Choosing a new model may require later questions to finish that branch; the initial question is never repeated per spawn. An explicit user request to use subagents answers delegation intent (Axis A); it does not choose the model/effort (Axis C). This is not a question about whether to delegate; the parent decides that from the task and `SPAWN.md`. **Only the parent asks**; a child never asks (`QUESTIONS.md`). The initial menu choice is never persisted. The active pair may update the existing preference only under the confirmed-use contract below; explicit `adt-settings` operations remain available.

### When

- At session start, before the active skill/task is processed, after effective `subagents=native` and `orchestrator_mode` have been resolved. This applies even when the task later stays in-parent under `adaptive`.
- Never when the effective `subagents` capability is `none` (`subagents=none`): nothing is spawned, so there is nothing to choose.
- If several spawns are ready before the answer, ask one question; every spawn waits for it.

### Question

- Present it once. State `presented`, then `pending` until `answered` (`QUESTIONS.md` States). Silence, a queued message, or an unrelated reply is not an answer, and nothing is spawned while the question is `pending`.
- The initial session question has three outcomes: `inherit`, `reuse_saved`, or `choose_model`. Before showing `reuse_saved`, revalidate the complete saved pair against the exact supported choices and encoding for the active adapter and surface. If the preference is unreadable, incomplete, or incompatible, omit `reuse_saved`, preserve the saved content, and leave inheritance and new-model selection available.
- Label a legacy value as a saved configuration. Do not call it proven or previously confirmed until the operator confirms that its use worked.
- `choose_model` starts the new-model selection branch. Do not put an extended model/effort combination list in the initial question; the branch's prompts follow the active adapter's supported options.
- Before composing the question, inspect the current adapter row in `SUBAGENT-OPTIONS.md` and the live read-only model/effort choices exposed by the active host surface. Do not rely on a generic catalog or a different CLI/app surface. For Claude Code, inspect the current `/model` and effort choices without selecting a new parent setting, then confirm that the active subagent invocation supports the complete pair.
- Render the initial choice by `QUESTIONS.md`: use a host component when its mechanism is identified or the row is explicitly `operator-confirmed component`, and the answer is observable; otherwise use numbered text. The operator confirms usable question components for Codex, Claude, Cursor, Hermes, and Copilot; this report does not extend to other hosts. Preserve the observable numbered-text fallback for unverified hosts or when the component does not return an answer.
- For Codex, inspect the parent's live `collaboration.spawn_agent` tool schema. Extract and enumerate every literal value in the `model` enum and the `reasoning_effort` enum before asking; reporting only that those two fields exist is incomplete discovery. Label model slugs as `SESSION_SCHEMA` / requestable and model-specific effort support from the official per-model docs as `DOCUMENTED` / requestable, not runtime-verified. Treat the two schema fields as separate: offer only combinations supported by an explicit schema constraint or compatible per-model documentation, never their assumed Cartesian product. If the schema is not machine-readable to the toolkit, read the parent-visible tool definition directly and enumerate its enum values in the session context. If a field has no exposed enum, state that exact limitation. When `reasoning_effort` is an unconstrained string with no enum, use compatible per-model docs to discover supported values; do not infer a generic cross-product.
- In the `choose_model` branch, ask for the model first using only choices exposed by the active adapter and surface. After the operator selects a model, derive its supported efforts from that same source and show only the supported values among `low`, `medium`, and `high`, in that order. Do not show a cartesian list of model/effort combinations or infer compatibility.
- Disclose available model choices immediately before the model question. After a model is selected, disclose only its documented or observed support among `low`, `medium`, and `high` before the effort question; do not list other effort values or model/effort pairs. If none of those three values is eligible, skip the effort question and continue by inheriting the parent's model and effort.
- If no model choice or no eligible effort can be discovered for the active surface, do not invent a model, effort, alias, or compatibility claim. Keep inheritance available and omit both override values unless a complete pair is selected through supported choices.
- Ids are stable English tokens; labels are in the user's language. A selected pair is session intent, not proof that the host applied it; actual effective values remain unknown unless the host reports them.
- A saved general default may populate `reuse_saved` after compatibility validation; it never answers the question by itself.
- While the question is pending, a clarification does not reset its state or create a duplicate model question. Answer the clarification without repeating the pending question; do not replace it with a yes/no question such as whether to inherit. Wait for the operator to answer the already-presented choice. An invalid answer may be explained once, but the same question is not emitted again.
- An explicit request that names a complete, currently discovered pair before the first delegation answers the question without asking again. An invalid, undiscovered, or partial pair does not answer it: warn once naming the field and reason (never echo the invalid value), then present the current supported choices.
- An explicit abstention or `inherit` means inherit. `reuse_saved` applies only the eligible saved pair, and `choose_model` proceeds into the new-model branch. The choice itself never writes the saved preference.

### Confirmed-use preference update

- After the parent has used the complete active pair, ask the operator a simple confirmation such as “Funcionou?”. An explicit confirmation that it worked is sufficient; do not request logs, captures, or another artifact.
- Only confirmation for the pair actually used authorizes a preference update. Inheritance, no use, no confirmation, a non-confirming answer, or a host refusal followed by inheritance leave the prior preference unchanged.
- Update only the existing `subagent_models.default` field with the complete pair that was used. Do not add history, a proof flag, or another preference key. This confirmation does not persist proof metadata; a saved value remains labeled “saved configuration” in a later session.
- Use the field-scoped read/compare/write/read-back safeguards in `adt-settings/SKILL.md` § Edit rules. Preserve all other keys. If writing or read-back fails, restore the prior content, report the failure without claiming the pair was saved, and let the current session continue with its active choice.
- This update flow does not change the explicit query/save/inherit operations offered by `adt-settings`.

### Apply

- `inherit`: call the spawn tool and **omit both** `model` and `effort`.
- `reuse_saved`: reread and apply only the complete saved pair validated for the active adapter and surface. Never infer compatibility from a different adapter, surface, version, or stale catalog. An unreadable or incompatible preference is not changed; omit both overrides and inherit.
- `choose_model`: apply only the complete pair selected in the new-model branch.
- Pair: use only the native mechanism written in the current adapter row of `SUBAGENT-OPTIONS.md`; never assume parameter names. If any part of the pair lacks proven support, or `SUBAGENT-OPTIONS.md` is missing or unreadable, omit both, warn once, and keep the choice unchanged. If the host refuses a reused pair, make one inheritance attempt that omits both parameters. `effort=unverified` is never sent. Never combine a chosen model with an inherited effort.
- Never raise model or effort on the toolkit's own initiative.
- When reporting a delegation, state the source (session choice or inherited), the requested pair, the parameters sent, and the effective value only if the host reports it. Requested, sent, and effective values are distinct. A child's statement about its own model is not evidence.
- The child prompt never contains preferences, their paths or structure, or the content of `SUBAGENT-OPTIONS.md`.

### Refusal and fallback

1. If the host refuses a spawn that carried the pair, make **one inheritance attempt** omitting both parameters.
2. Keep the answered choice as the session intent. Record, in the parent's session control only, the refused pair and the refused context (adapter, surface, version or schema, source or route). This record is not a preference, toggle, role map, or receipt field.
3. While the refused context is unchanged, later spawns omit the refused pair with no new attempt, question, or warning.
4. An explicit request for the refused pair, or a proven change of the refused context, triggers one revalidation of eligibility against `SUBAGENT-OPTIONS.md`. Still ineligible: inherit for that call and say so once. Eligible: send the pair once, with the same one-inheritance-attempt rule.
5. If the inheritance attempt also fails, use only the fallback the workflow already allows (the parent executes where the workflow permits it, otherwise manual handoff). The task stays incomplete until a real execution succeeds. A failure never stops the remaining authorized work and never lets the parent implement under O3.

### Non-interactive sessions, compaction, replacement

- Continuous, O3 queue, or any session that cannot ask: use the choice recorded at session start. With no recorded choice, or with `SUBAGENT-OPTIONS.md` or preferences missing or unreadable, omit both parameters.
- After a context **compaction** the answered choice and any refused context stay in force; the question is not repeated. State the choice in one chat line right after the answer so a summary keeps it.
- A new conversation asks again. A later explicit request replaces the choice for the following spawns only.

## Host UI limit (RNF-003)

Toolkit enforces Axis B/C in **skills**, **publish honesty**, and **CI**. If the **host UI** rewrites the child model after spawn, that rewrite is **outside** toolkit control — document the limit; do **not** claim a hard runtime guarantee against UI override.

## Must not

- Pass `model` or `effort` outside the session choice
- Ask the question more than once per session, per spawn, or from a child
- Treat silence as an answer
- Persist the initial menu choice, or update the saved pair before the confirmed-use contract is satisfied
- Send a pair without proven support, or send `effort=unverified`
- Write model identifiers, aliases, or effort values in this file (they come from `SUBAGENT-OPTIONS.md`)
- Rely on hooks to enforce model choice (hooks never select models)
- Confuse Memory Bank policy `auto` with a host auto model
- Overclaim that CI/skills prevent host-UI model rewrite after spawn
