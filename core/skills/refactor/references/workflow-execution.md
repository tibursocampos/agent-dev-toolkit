## Workflow decision and step-by-step execution

### Workflow path selection

* Present the summary of identified code smells and debt.
* Stop and ask the user to choose the workflow execution path based on the scope:
  * **Option A - Direct Developer Skill (`/developer`):** For straightforward local refactoring edits.
  * **Option B - Classic SDD (`/sdd-spec` -> `sdd-plan` -> `sdd-develop`):** For complex structural refactorings requiring a formal specification (PRD) and a step-by-step checklist (PLAN) in Portuguese.
  * **Option D - Plain Chat Plan:** Establish a simple task list directly in the chat, executing steps one by one without extra file creations.
* **Wait for explicit user choice** before writing code or initializing another workflow.

### Step-by-step execution and validation

* For each accepted refactoring step:
  * Apply the minimum diff modification.
  * Run compiler checks (e.g. `dotnet build`, `npm run build`, `mypy` or build/typecheck commands).
  * Run the unit test suite (e.g. `dotnet test`, `npm test`, `pytest`).
  * Before any recovery, record the working tree state (staged, unstaged, untracked, and concurrent changes) and treat it as pre-existing work to preserve.
  * If validation fails: preserve pre-existing and concurrent changes. Roll back only changes demonstrably made by this step and reversible. If authorship of any change is uncertain, stop and report it instead of rolling back automatically. Explain the failure and discuss alternatives.
  * If validation passes, proceed to the next step.

### Code formatting

* Once all steps are complete, run the target formatter on the refactored files (e.g. CSharpier, Prettier, Black, Ruff) to align with style rules.

### Handoff

Ask the user if they want to review the final diff and hand off to `/commit`.
