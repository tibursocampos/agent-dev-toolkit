# Toolkit hooks

Toolkit hooks are optional helpers published by adapters. They are not the policy engine and they are not the host's permission system.

## What hooks may do

Context hooks can observe a prompt boundary, a file edit, or a compaction boundary and surface a checkpoint or compact context. They may record local state needed by the toolkit. They should be safe to skip: policy still applies when hooks are absent, disabled, unsupported, or unavailable.

| Event | Purpose | Boundary |
| --- | --- | --- |
| `beforeSubmitPrompt` | Track relevant skill/session intent | Always allows submit; it does not approve work. |
| `preToolUse` | Guard obvious unsafe writes/secrets where supported | Does not replace toolkit gates or host approval. |
| `afterFileEdit` | Record an artifact checkpoint | Does not validate product correctness. |
| `preCompact` | Surface context checkpoint guidance | Does not inspect private transcripts or choose a model. |

Exact event names and support vary by adapter. Unsupported events are simply absent.

## Permission prompts are different

A host permission prompt is rendered by the host and controls whether that host will execute a particular operation. It is not a toolkit hook. A hook can report context before or after an operation, but it cannot manufacture, answer, or broaden a host permission prompt. Conversely, host approval does not satisfy a toolkit `sim` confirmation or an SDD session gate.

## Host placement

Hooks are installed only where the adapter documents them. Cursor-style hooks live under the adapter's install-root hooks directory; Claude and other hosts use their native hook/settings locations when supported. Copilot instruction placement is separate from hook placement: user mode targets the user's Copilot tree, while repo mode targets `.github/` in the consumer repository. Do not create a project-local `.cursor/hooks.json` merely to enable toolkit hooks.

## Impeccable coexistence

The optional Impeccable live/design hook may be installed in a consumer project only after explicit consent. Merge it with existing toolkit/host hooks; do not overwrite unrelated entries. See [impeccable-integration.md](impeccable-integration.md).

## Non-goals

Hooks do not select models, classify model cost, read host session JSONL as a required dependency, implement SDD gates, or make a failed policy check pass. When a hook fails, record the limitation and continue with the portable policy path.
