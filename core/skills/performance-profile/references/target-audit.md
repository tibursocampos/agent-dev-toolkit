## Target identification and static audit

### Target identification

* Locate the target method, database routine, or loop structure.
* Confirm what metrics are critical: Execution Time (ms) or Memory Allocation (MB/GC cycles).

### Static performance audit and workflow decision

* Analyze the target code for common anti-patterns:
  * Database: N+1 queries (no eager loading), lack of projection (`select new`), missing query limits (`Take`/`limit`), unindexed search fields.
  * Memory: Excessive allocations inside loops, duplicate string concatenations, boxing/unboxing.
* Present the diagnostic report summarizing the bottlenecks.
* Stop and ask the user to choose the workflow execution path for applying and benchmarking these optimizations:
  * **Option A - Direct Developer Skill (`/developer`):** For straightforward local optimization and benchmark setup.
  * **Option B - Classic SDD (`/sdd-spec` -> `sdd-plan` -> `sdd-develop`):** For complex structural refactorings or query tuning requiring formal specifications (PRD) and a detailed plan (PLAN) in Portuguese.
  * **Option D - Plain Chat Plan:** Establish a simple task list directly in the chat, executing steps one by one without extra file creations.
* **Wait for explicit user choice** before writing code or initializing another workflow.
