# Portable question and gate contract (operator questions)

Canonical contract for **how** the agent asks the operator a blocking question, **how** an answer maps to a stable id, and **when** dependent work may continue. Orthogonal to **when** to spawn (`SPAWN.md`) and to **which** language each surface uses (`LANGUAGE.md`).

Install path after sync: `{{TOOLKIT_ROOT}}/skills/_shared/agents/QUESTIONS.md`

Other files point here. Gate wording and blocking rules are not restated elsewhere.

## Order rule

1. If the host offers a question component (see the host mechanism table) **and** the selected answer is returned to the agent in an observable form, use the component and wait.
2. If the component cannot open, or its answer does not reach the agent, ask in text in the conversation language with numbered options.
3. In both cases the flow blocks. The question stays `open_question` until its state is `answered` (see States). Silence, a timeout, or the end of the turn is never an answer.

A host **offers** a question component only when the host mechanism table below names a tool for it. No other signal counts as an offer.

## Host mechanism table

| Host | Mechanism | Evidence in this repo |
|------|-----------|-----------------------|
| `claude` | `AskUserQuestion` | `adapters/_shared/GuardCommon.ps1` `Test-ToolkitReadOnlyToolName`, `$readOnlyTools` entry `claude` |
| `grok` | `AskUserQuestion` | `adapters/_shared/GuardCommon.ps1` `$readOnlyTools` entry `grok` |
| `zcode` | `AskUserQuestion` | `adapters/_shared/GuardCommon.ps1` `$readOnlyTools` entry `zcode` |
| `hermes` | `ask_user` | `adapters/_shared/GuardCommon.ps1` `$readOnlyTools` entry `hermes`; `adapters/hermes/assets/plugins/agent-dev-toolkit-guard/__init__.py` (`ask_user` in the read-only tool list) |
| `cursor` | `none` | No verified question component. |
| `antigravity` | `none` | No verified question component. |
| `codex` | `none` | No verified question component. |
| `copilot` | `none` | No verified question component. |
| `opencode` | `none` | No verified question component. |
| `openhands` | `none` | No verified question component. |

Rules for this table:

- `none` means no verified question component: ask in numbered text. For a host marked `none` the tool name must not be invented.
- Use only the row for the current host. Never invoke another host's tool.
- A name in the evidence column shows that the toolkit knows the tool name. It does not prove that the answer returns to the agent. Treat the mechanism as usable only after a live run shows the selected answer reaching the agent, and record that run in the adapter evidence (`adapters/README.md`).

## Decision: no capability flag in this phase

The table above is the contract. No `interactiveQuestion` capability is added to `adapters/registry.json` or `adapters/_contract/AdapterContract.ps1`. Reason: keeps this change small. The capability can be added later if a validator needs it.

## Option schema

- **Ids** are stable English tokens. They never change with the conversation language.
- **Labels and descriptions** are written in the user's conversation language.
- **Single select** is the default. Use multi-select only when the options are not mutually exclusive, and say so in the question.
- **Other / free text** is always allowed. It maps to `adjust` when it changes the proposal, or to an open answer where the question is open (see Legitimate free text).
- **Header** is one short line.
- **At most 4 options** per question. Split a longer question into several.

Common ids:

| Id | Meaning |
|----|---------|
| `confirm` | Approve the exact action or artifact shown. |
| `adjust` | Change the proposal before acting. |
| `cancel` | Stop. Do not perform the gated action. |
| `skip` | Leave an optional step undone and continue. |
| `decline` | Refuse an optional offer. |
| `feature`, `tech` | Requirement-review mode (`requirement-review`). |
| `split` | Divide a story before drafting. |
| `manual`, `orchestrated` | Execution route for one PLAN step. |
| `series`, `parallel` | Orchestrated Delivery drafting mode. |

Domain ids are added per gate. They are still English and must be listed in the owning skill's contract.

`series` / `parallel` (orchestrate-deliver drafting mode) and `serial` / `parallel` / `manual` (orchestrate-develop queue mode) are distinct id sets for distinct questions.

## Answer to id mapping

- **Component selection** maps directly to the id the host returns.
- **Text answer**: a clear affirmation, adjustment, or cancellation in any language maps to `confirm`, `adjust`, or `cancel`. Examples of `confirm`: "yes", "sim", "ok", "oui", "好", "نعم".
- A reply that affirms and also changes the scope in the same message maps to `adjust`. Re-present the changed proposal before asking again.
- An isolated emoji, silence, or an ambiguous or unrelated reply keeps the question `pending`.
- Gate words in the user's language (for example `sim` / `ajustar` / `cancelar`) are labels. The ids behind them are `confirm` / `adjust` / `cancel`.

## Legitimate free text

Open questionnaires take free text on purpose. Example: the intake questions in `sdd-spec`. Those questions have no fixed id set. The answer is recorded as text, and the question still blocks until it is answered.

## States

| State | Observable condition | May dependent work continue? |
|-------|----------------------|------------------------------|
| `presented` | The exact question, choices, and affected scope are in the current conversation. | No |
| `pending` | The prompt was emitted, but no supported answer has been processed. Silence, a queued message, a notification, or an unrelated reply stays pending. | No |
| `answered` | The agent has received and parsed an allowed answer for this question and can name the selected id. | Only the branch that answer authorizes |
| `resumed` | After an interruption or a new turn, the agent reloaded the pending question and confirmed which one is still active. | No, until the question becomes `answered` |

`orchestrate-deliver/references/approval-gates.md` uses these same states and points here.

Record the question id or scope, the accepted answer form, and the resulting transition in the current turn or in the persistent workflow artifact where one exists. On resume, repeat the active question or present its current status. Never infer an answer from earlier unrelated text.

A host displaying, queuing, retrying, or redelivering a message is not proof that the agent processed it. When the surface cannot expose processing events, report that boundary and keep the state `pending` until an answer reaches the agent. Toolkit instructions cannot force a host UI to show, retain, or retract a prompt.

## Git and write gates

An observable selection of a question component satisfies the **sim** requirement in `guardrails.md` sections 1 and 2 for the exact action asked. A clear text `confirm` in any language does the same. The approval covers only that action. It does not carry over to later actions.

Keep technical authorization, scope, and persisted session gates as separate checks.

## Caveman

Gates are never compressed. The protected text is the gate text in the user's language. It is not a fixed pt-BR literal. Component labels and descriptions are not compressed either. Auto-Clarity still applies to security and irreversible confirmations.

## Subagents

Children never ask the operator. Only the parent asks. A child that needs an answer stops its pass and reports the need in its receipt (`RECEIPT.md`): the `needs-confirm.` token, plus the question, its ids, and its scope. The child writes the receipt in en-US. The parent renders the question in the user's language and asks it, then blocks as above.

## Cross-refs (lazy-load)

| File | Use |
|------|-----|
| `core/policy/guardrails.md` | Blocking rule and the git and write gates that point here |
| `core/skills/orchestrate-deliver/references/approval-gates.md` | Gate prompts for Orchestrated Delivery; uses the states defined here |
| `LANGUAGE.md` | Which language each surface uses; the gate text in the user's language |
| `SPAWN.md` | When to spawn; children report questions through the receipt |
| `RECEIPT.md` | Receipt schema and the `needs-confirm.` refusal token |
| `adapters/README.md` | Per-adapter evidence and retry or redelivery limits |

## Must not

- Ask a blocking question by a mechanism that the host table does not name for the current host.
- Invoke another host's question tool.
- Invent a tool name for a host marked `none`.
- Treat silence, a timeout, an emoji alone, or the end of a turn as an answer.
- Let a host-component selection stand for an answer the agent did not receive.
- Let one approval cover a later action.
- Compress gate text or component labels under Caveman.
- Let a child ask the operator directly.
