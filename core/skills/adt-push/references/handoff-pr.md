## PR handoff via `/adt-open-github-pr` (required)

After a successful push, decide:

**A) User already asked for a PR in this conversation** (same or earlier turn) — examples: `fluxo completo`, `abra o PR`, `abrir PR`, `criar PR`, `faça o PR`, `open the PR`, `create pull request`, `commit + push + PR`, or answered `confirm` to a prior PR offer.

→ **STOP** `/adt-push` and **immediately** load `{{TOOLKIT_ROOT}}/skills/adt-open-github-pr/SKILL.md`. Follow it end-to-end (mode, template, body confirmation, **mandatory auto-merge ask**). Do not create the PR inside `/adt-push`.

**B) No prior PR intent** — **ask** in the user's chat language with the `confirm`, `decline`, and `cancel` choices (ids and render rule: `core/skills/_shared/agents/QUESTIONS.md`); do **not** create the pull request inside `/adt-push`.

Render the question in the chat language: the push finished, and the user is asked whether to open a pull request with `/adt-open-github-pr`. `confirm` invokes that skill. `decline` or `cancel` ends this step.

- On `confirm` (or explicit `/adt-open-github-pr`): **STOP** this skill and hand off — load and follow `{{TOOLKIT_ROOT}}/skills/adt-open-github-pr/SKILL.md` in the same or new turn (mode feature by default unless user said release). That skill owns template, body confirmation, and auto-merge ask.
- On `decline` or `cancel`: stop. Do not open a PR. Silence, an ambiguous or unrelated reply, or a lone emoji is not approval.
- Web UI is **not** offered from `/adt-push`; only `/adt-open-github-pr` may mention web UI as its own fallback when the CLI is missing.
