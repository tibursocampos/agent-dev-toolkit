## Scan for string literals and workflow decision

* Read target files and identify raw text content in HTML tags or hardcoded string variables.
* **Filter out:**
  * Log templates (like warning logs).
  * System keys (like routing paths, config names, constants, and dictionary keys).
* Present a list of candidate strings with suggested keys (e.g. `WelcomeMessage`, `SubmitButtonLabel`).
* Stop and ask the user to choose the workflow execution path, in the user's chat language. Options are labelled A, B, C in this order, with these ids (answer rule: `core/skills/_shared/agents/QUESTIONS.md`):
  * **A - `developer`:** Direct Developer Skill (`/developer`). For straightforward local string extraction and key replacements.
  * **B - `sdd`:** Classic SDD (`/sdd-spec` -> `sdd-plan` -> `sdd-develop`). For massive application-wide localization tasks requiring a PRD and a detailed PLAN. Their language follows `core/skills/_shared/agents/LANGUAGE.md`.
  * **C - `chat-plan`:** Plain Chat Plan. Establish a simple task list directly in the chat, executing steps one by one without extra file creations.
* **Wait for explicit user choice** before writing code or initializing another workflow.
