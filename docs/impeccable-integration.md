# Impeccable integration

The toolkit's `impeccable` skill is a partial design harness. It hands off through `docs/DESIGN-BRIEF.md`; it does not silently install upstream Impeccable hooks.

## Live mode and design hooks

`npx impeccable install` changes the consumer project by adding Impeccable files and hook configuration. Run it only after explicit user confirmation for that project. The toolkit's policy and host permission prompts remain authoritative.

If the project already has hooks, merge the Impeccable entry with the existing configuration. Preserve unrelated entries, avoid duplicate commands, and do not replace toolkit context helpers. A hook is an integration aid, not a substitute for a toolkit policy or SDD gate.

## Boundaries

- Toolkit hooks remain optional and context-only; see [HOOKS.md](HOOKS.md).
- Impeccable live mode may require a local browser/server and host approval.
- Model choice and model-cost awareness remain host/policy concerns, not Impeccable hook behavior.
- The normal handoff is `impeccable` → `docs/DESIGN-BRIEF.md` → the relevant stack skill.
