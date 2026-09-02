## Draft configuration and workflow decision

* Explain the proposed container strategy:
  * Base images to use (e.g. `mcr.microsoft.com/dotnet/aspnet:8.0-alpine` or `node:20-alpine`).
  * Port maps and network parameters.
  * Required local services in compose.
* Stop and ask the user to choose the workflow execution path to build and verify these configurations:
  * **Option A - Direct Developer Skill (`/developer`):** For straightforward local creation of Dockerfiles/Compose.
  * **Option B - Classic SDD (`/sdd-spec` -> `sdd-plan` -> `sdd-develop`):** For complex environment containerization requiring formal specifications (PRD) and a detailed plan (PLAN) in Portuguese.
  * **Option D - Plain Chat Plan:** Establish a simple task list directly in the chat, executing steps one by one without extra file creations.
* **Wait for explicit user choice** before writing code or initializing another workflow.
