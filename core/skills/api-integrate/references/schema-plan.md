## Detect stack, locate schema, and plan

### Detect tech stack and locate schema

* Identify target project language and preferred HTTP client patterns.
* Locate the OpenAPI spec (ask user or load the specified file path). Validate that the file is readable.

### Plan structure and workflow decision

* Propose the client layout:
  * Destination folder (e.g. `src/services/` or `Infrastructure/Clients/`).
  * File splits: client interface, models, configuration.
* Present the summary of identified API endpoints, routes, and request/response shapes.
* Stop and ask the user to choose the workflow execution path based on the integration scope:
  * **Option A - Direct Developer Skill (`/developer`):** For straightforward local client generation.
  * **Option B - Classic SDD (`/sdd-spec` -> `sdd-plan` -> `sdd-develop`):** For complex third-party integrations requiring formal specifications (PRD) and a detailed plan (PLAN) in Portuguese.
  * **Option D - Plain Chat Plan:** Establish a simple task list directly in the chat, executing steps one by one without extra file creations.
* **Wait for explicit user choice** before writing code or initializing another workflow.

**Boundary:** this skill owns **typed client / DTO generation** from OpenAPI. Agnostic API **standards** packing belongs to the separate `api-standards` skill (do not expand standards content here).
