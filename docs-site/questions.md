---
title: Questions
---

# Questions

Some steps stop and wait for you. The agent asks a question, shows the choices, and does not continue until it has an answer it can read. This page explains how the question is asked and how to answer it. The rules come from `core/skills/_shared/agents/QUESTIONS.md`. For the skill ids, see [Using skills](using-skills.md).

## How the agent asks

The agent uses the host's native question component only when your selected answer comes back to the agent. If the host has no such component, or the answer would not reach the agent, the agent asks in plain text with numbered options, in the conversation language.

Either way, the flow waits. The question stays open until it is answered. Silence, a timeout, or the end of a turn is not an answer.

## How to answer

Answer in your own language. Any of these works:

- Pick an option in the question component, when one appears.
- Reply in text with a clear yes, a request to adjust, or a cancel. For example: "yes", "sim", "ok", "oui".

The agent maps your reply to a stable id:

| Your reply | Id | Meaning |
|------------|----|---------|
| A clear yes | `confirm` | Approve the exact action or artifact shown. |
| A request to change the proposal | `adjust` | Change the proposal before acting. |
| A stop | `cancel` | Do not perform the gated action. |

Some replies keep the question open:

- Silence or a timeout.
- A lone emoji.
- An ambiguous or unrelated reply.

A reply that agrees and also changes the scope maps to `adjust`. The agent shows the changed proposal and asks again. Free text that changes the proposal also maps to `adjust`.

## Gate ids and labels

Ids are stable English tokens. They do not change with the conversation language. The labels you see follow the conversation language.

| Id | Meaning | Label (English) |
|----|---------|-----------------|
| `confirm` | Approve the exact action or artifact shown. | yes |
| `adjust` | Change the proposal before acting. | adjust |
| `cancel` | Stop. Do not perform the gated action. | cancel |
| `skip` | Leave an optional step undone and continue. | skip |
| `decline` | Refuse an optional offer. | no |

Gate words in your language are labels. The ids behind them are the same in every language.

An approval covers only the action it was given for. A `confirm` for one write or one commit does not approve the next one.

## Which hosts show a question component

The agent uses only the row for its own host. A tool name in this table means the toolkit knows the tool. The component is used only when the answer reaches the agent. Otherwise the agent asks in text.

| Host | Mechanism |
|------|-----------|
| `claude`, `grok`, `zcode` | `AskUserQuestion` |
| `hermes` | `ask_user` |
| `cursor`, `antigravity`, `codex`, `copilot`, `opencode`, `openhands` | None. Numbered text questions. |

## Who asks

Only the main session asks you questions. Subagents never ask you directly. When a subagent needs an answer, it stops and reports the question in its receipt. The main session then asks you and waits.

## Free-text questions

Some questions are open on purpose. The intake questions in `sdd-spec` are one example. They have no fixed set of ids, and your answer is recorded as text. The question still waits until you answer it.
