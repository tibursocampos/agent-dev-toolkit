# api-standards — command playbook

**Load after Step -1 gates.** Ordered step discovery without dumping `SKILL.md` Process. Load **one** section file per step (`SKILL-REFERENCE-RETRIEVAL.md`).

| Step | Action | Lazy section / contract |
|------|--------|-------------------------|
| -1b | Caveman Full when active | `CAVEMAN.md` |
| -1 | Re-check guardrails + session | — |
| 0 | Scope: standards vs client gen; pick focus areas (≤3) | `SELECTIVE-RETRIEVAL.md` |
| 1 | Optional inspect of routes / OpenAPI / controllers | — |
| 2 | Apply standards one playbook at a time | `references/rest-http.md`, `references/versioning.md`, `references/errors-pagination.md`, `references/naming-contracts.md`, `references/security-agnostic.md` |
| 3 | Report gaps; hand off client gen if needed | `api-integrate`; `references/must-not.md` |

Boundary: packing/guidance only — no proprietary contracts; no typed client generation in this skill.
