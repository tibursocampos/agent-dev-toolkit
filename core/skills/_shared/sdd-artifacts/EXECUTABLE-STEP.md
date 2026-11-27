# Executable step contract

Owner of the full rule. Each planning and execution skill repeats a short block that points here. Read this file when you write, check or execute a step.

## Definition

A step is executable when a less capable agent can make the change by reading only:

1. the step,
2. the files the step names,
3. the decisions the step cites.

If the agent needs anything else, the step is not executable.

## Required content of every step

| Field | Rule |
|---|---|
| Result | One sentence, observable. |
| Files | Exact repository-relative path for each file, marked `modify` or `create`. |
| Symbols | Exact name for each class, method, constant, property or key, with `path:line` read in this session, or `create`. |
| Contract excerpt | When the step creates or changes a contract (signature, JSON, request or response, error payload, command, config key), a code block with the exact text. |
| Edits | Numbered. One change per item. For existing text: the exact old text and the exact new text. |
| Validation | One command and its filter, for example `dotnet test --filter FullyQualifiedName~X`, or `grep -n "text" path`. |
| Acceptance | IDs of the criteria the step covers. |

## Forbidden in an approved step

- Words that postpone a choice: `a confirmar`, `TBD`, `se necessário`, `ajustar se`, `conforme adequado`, `decidir`, `escolher`, `etc.`.
- A reference to another step's result without that result's excerpt.
- A file or symbol that is not marked `modify`, `create`, or read in this session.

## Planner self-check (one pass)

For each step, answer:

1. Does every file exist, or is it marked `create`?
2. Was every symbol read in this session, or is it marked `create`?
3. Does the step contain no forbidden word or pending reference?

Fix each `no` once, then present the plan. No second review round.

## Implementer rule

Before editing, check the step against the three questions above.

- If the step passes: execute it.
- If the step fails: mark it BLOCKED with `plan defect: <what is missing>`, and return to the planner. Do not guess.
- A business or architecture decision that the step leaves open goes to the operator, once. Style, naming and project patterns are settled from the existing code and recorded in the step.

## Example

Not executable:

```text
S2. Adjust the handler to return the right status for a denied payment. Check the tests.
```

Executable:

```text
S2. Denied payment returns HTTP 402.
Files: modify src/Payments/PaymentController.cs; modify tests/Payments/PaymentControllerTests.cs.
Symbols: PaymentController.Pay (src/Payments/PaymentController.cs:41, read); PaymentStatus.Denied (src/Payments/PaymentStatus.cs:9, read).
Contract:
    HTTP 402, body {"error":"PAYMENT_DENIED"}
Edits:
1. In PaymentController.Pay, before the return, add: if status == PaymentStatus.Denied, return StatusCode(402, new { error = "PAYMENT_DENIED" }).
Validation: dotnet test --filter FullyQualifiedName~PaymentControllerTests.Pay_Denied
Acceptance: A2.
```
