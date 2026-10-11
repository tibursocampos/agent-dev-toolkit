# Optional upstream Impeccable

The toolkit does not distribute an Impeccable skill or install its CLI. For UI work, record visual decisions in the project’s `docs/DESIGN-BRIEF.md`, then use the relevant stack skill. General design and frontend engineering guidance remains available in `core/skills/_shared/frontend-guidelines/`.

The upstream Impeccable project and CLI are independent and optional. Their installation, runtime, and files are outside toolkit publication and cleanup.

## Live mode and design hooks

`npx impeccable install` changes the consumer project by adding Impeccable files and hook configuration. Use it only when the user explicitly requests installation and confirms the target project. The toolkit's policy and host permission prompts remain authoritative.

If the project already has hooks, merge the upstream entry with the existing configuration. Preserve unrelated entries, avoid duplicate commands, and do not replace toolkit context helpers. A hook is an integration aid, not a substitute for a toolkit policy or SDD gate.

## Boundaries

- Toolkit hooks remain optional and context-only; see [HOOKS.md](HOOKS.md).
- Impeccable live mode may require a local browser/server and host approval.
- Model choice and model-cost awareness remain host/policy concerns, not Impeccable hook behavior.
- Separate integrations or scopes can coexist. Two copies in the same harness and scope can create duplicate skills or hooks; check the target before installation.
- The design handoff is `docs/DESIGN-BRIEF.md` → the relevant stack skill. Installing the upstream CLI is optional.
