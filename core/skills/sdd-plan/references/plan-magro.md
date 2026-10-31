## PLAN magro

Do not paste SQL/DDL/JSON/OpenAPI into the PLAN. Cite a canonical path (bank phase 2 or story `ARCH/` / `ANALYSIS/`) and keep the body in that artifact.

Resolve `invocation_context` once per run (`INVOCATION-CONTEXTS.md`):

| Context | Missing canonical body or O1-only sibling | Owner and timing |
|---|---|---|
| `orchestrated` | **STOP**. Do not write the PLAN or emit an O3 handoff. Return to O1/O2 with the missing portable path. | O1/O2 creates or promotes the canonical artifact before the PLAN boundary; O2 owns the PRD/PLAN handoff. |
| `direct` | Ask the operator to choose: (1) create the body/sibling inline in this session, (2) continue with an explicit operator-risk record and a PLAN path to be completed, or (3) use optional `/orchestrate-analyze`. Do not hard-block solely because an O1-only sibling is absent. | `sdd-spec`/`sdd-plan` owns the direct write it performs; the operator owns an accepted risk. The PLAN still cites the canonical path and must not contain the body. |

The direct risk choice is not silent permission to invent a contract: record the missing path, the assumption/risk, and the follow-up owner in the PLAN or its cited `ANALYSIS/ARCH` note. If the operator does not choose inline or risk, stop and ask again.

### Direct context

In `direct`, an approved canonical PRD is sufficient; absent O1/O2 siblings do not trigger acquisition or an operator-risk choice. Normalize complexity from the persisted PRD field using `checklist-acquisition.md`; derive PLAN-native steps from approved behavior/REQ/CA without checklist IDs. STORY/checklist may supplement only when explicitly linked or provided, and cannot override the PRD. Keep this distinct from the PLAN-magro rule above: if an omitted technical body has no canonical source, use the documented direct operator choice.

In `orchestrated`, O1/O2 must provide the canonical bodies and required siblings before PLAN. O2's FEATURE/STORY, approvals, analysis, and checklist requirements remain in force; do not use the direct fallback.

---
