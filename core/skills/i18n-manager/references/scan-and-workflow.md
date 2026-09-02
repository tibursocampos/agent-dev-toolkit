## Scan for string literals and workflow decision

* Read target files and identify raw text content in HTML tags or hardcoded string variables.
* **Filter out:**
  * Log templates (like warning logs).
  * System keys (like routing paths, config names, constants, and dictionary keys).
* Present a list of candidate strings with suggested keys (e.g. `WelcomeMessage`, `SubmitButtonLabel`).
* Stop and ask the user to choose the workflow execution path:
  * **Option A - Direct Developer Skill (`/developer`):** For straightforward local string extraction and key replacements.
  * **Option B - Classic SDD (`/sdd-spec` -> `sdd-plan` -> `sdd-develop`):** For massive application-wide localization tasks requiring formal specifications (PRD) and a detailed plan (PLAN) in Portuguese.
  * **Option D - Plain Chat Plan:** Establish a simple task list directly in the chat, executing steps one by one without extra file creations.
* **Wait for explicit user choice** before writing code or initializing another workflow.
