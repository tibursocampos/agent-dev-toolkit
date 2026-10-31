## Fallback execution (no stack match)

### Subagent-first (before implement)

Stack `*-developer` skills own this policy when routed. In fallback mode: classify complexity → consult capability `subagents` → if medium/complex and `native`: spawn ≤2 children (scoped **paths** + **receipt**); **trivial** stays **in-parent**; if `subagents=none` or Agent unavailable → **fallback** **in-parent** (never hard-fail). Load `SPAWN.md` + `subagent-first.md`; do not paste guidelines into child prompts.

### 0. Workspace

Confirm target repo, read `README.md` (if exists), and summarize requested acceptance. Before choosing tests or validation, inspect existing test directories, runner/configuration, project scripts, and CI commands; preserve the repository's verified baseline.

For an existing repository, or when impact and local conventions are unclear, follow `{{TOOLKIT_ROOT}}/skills/_shared/agents/BROWNFIELD-ANALYSIS.md` before the first implementation change. Reuse parent-provided analysis only after checking that it is current and covers the target area; re-check changed or uncovered paths. Keep discovery proportional to the affected scope, cite representative local evidence, and surface material gaps rather than choosing toolkit or external examples as defaults. Stack-specific skills retain ownership of their commands and conventions; do not duplicate the full checklist here or in each stack skill.

### 1. Micro-plan

Checkpoint durable workflow progress at the workflow-defined boundaries; context usage does not add a stop gate.

### 2. Implement

Recheck applicable project patterns in the touched area before editing, using the shared brownfield analysis from Step 0. Discover architectural patterns in the touched area first. Follow `structure-and-quality.md` §1: an operator order and the established project style outrank the toolkit style bar. Do not restyle existing members without an explicit yes. On greenfield / no clear comment-language mirror, ask before writing narrative comments/docs (identifiers stay English).

Write clean, maintainable code following universal best practices for the target language (e.g., HTML, Bash, Python script).

### 3. Tests / Validation

Run the project's configured tests, scripts, or linting tools relevant to the change. If no test or validation baseline exists, choose a minimal check appropriate to the task; do not introduce a stack-specific runner by default in generic fallback mode.

### 4. Handoff

Offer `/commit`. Do not commit automatically.
