## Fallback execution (no stack match)

### Subagent-first (before implement)

Stack `*-developer` skills own this policy when routed. In fallback mode: classify complexity → consult capability `subagents` → if medium/complex and `native`: spawn ≤2 children (scoped **paths** + **receipt**); **trivial** stays **in-parent**; if `subagents=none` or Task unavailable → **fallback** **in-parent** (never hard-fail). Load `SPAWN.md` + `subagent-first.md`; do not paste guidelines into child prompts.

### 0. Workspace

Confirm target repo, read `README.md` (if exists), and summarize requested acceptance.

### 1. Micro-plan

Define 2-5 concrete tasks. Checkpoint context usage after each major change per `context-management.mdc`.

### 2. Implement

Write clean, maintainable code following universal best practices for the target language (e.g., HTML, Bash, Python script).

### 3. Tests / Validation

Run local scripts or linting tools to ensure the code executes without syntax errors.

### 4. Handoff

Offer `/commit`. Do not commit automatically.
