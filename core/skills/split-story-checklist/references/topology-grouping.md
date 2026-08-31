## Topological order (story checklist portable)

1. Build a directed graph from `Depends on: Step N` / `none`.
2. Reject cycles - ask user to fix deps before writing the file.
3. Assign **waves**: wave 0 = no deps; wave k = all deps in earlier waves.
4. Within a wave, apply layer/repo grouping below.
5. Document parallel-safe steps: same wave and different groups with no cross edges.

Do **not** invent external work-item predecessor links or fixed org-only stage names.

---

## Grouping heuristics

Apply in order **after** topology waves:

**a) Markdown sub-headings (`####`)** - e.g. `#### Backend - billing-api` -> one group per heading.

**b) Repository / service name** - steps mentioning different repos or deployable units group separately.

**c) Layer** - same repo but clear split: Domain/Application/Infrastructure/API -> "Backend"; UI/Angular/React -> "Frontend".

**d) Fallback** - ≤3 steps with no natural split -> single group `Implementation`.

**Limits:**

- Maximum **5** implementation groups - merge smallest adjacent groups if exceeded
- Minimum **1** implementation group when any non-test steps exist

**Test steps (mandatory split):**

Steps whose layer is `Tests`, `Integration tests`, `Testes`, or title contains "unit test" / "integration test" -> move to:

- `Tests - Backend` and/or
- `Tests - Frontend`

Do not leave test-only steps inside feature implementation groups.

---
