# Clear acceptance and step titles

Acceptance should describe a result a reviewer can recognize from relevant behavior, evidence, or validation. Use REQ/CA IDs when they make tracing easier; do not require a specific ID scheme, BDD form, test name, or fixed number of criteria.

Replace statements that convey only completion (for example, “works” or “as expected”) with the observable behavior or evidence that matters. A suitable check may be an automated test, manual observation, contract comparison, static inspection, or another proportionate method.

Prefer outcome-oriented step titles over names that only list a file or class. Technical targets may appear in the step's planned changes. If a change is genuinely limited to a configuration or document update, a concise title can identify that work while the step still states its purpose and acceptance.

When the plan depends on repository evidence, cite the portable path and section or symbol actually inspected. Distinguish observed behavior, inference, proposal, and evidence gaps; do not claim runtime behavior from static inspection.
