## PLAN magro

Do not paste SQL/DDL/JSON/OpenAPI into the PLAN. Cite a canonical path (bank phase 2 or story `ARCH/` / `ANALYSIS/`) and keep the body in that artifact.

Resolve `invocation_context` once per run (`INVOCATION-CONTEXTS.md`):

| Context | Missing canonical body or O1-only sibling | Owner and timing |
|---|---|---|
| `orchestrated` | **STOP**. Do not write the PLAN or emit an O3 handoff. Return to O1/O2 with the missing portable path. | O1/O2 creates or promotes the canonical artifact before the PLAN boundary; O2 owns the PRD/PLAN handoff. |
| `direct` | Ask the operator to choose: (1) create the body/sibling inline in this session, (2) continue with an explicit operator-risk record and a PLAN path to be completed, or (3) use optional `/orchestrate-analyze`. Do not hard-block solely because an O1-only sibling is absent. | `sdd-spec`/`sdd-plan` owns the direct write it performs; the operator owns an accepted risk. The PLAN still cites the canonical path and must not contain the body. |

The direct risk choice is not silent permission to invent a contract: record the missing path, the assumption/risk, and the follow-up owner in the PLAN or its cited `ANALYSIS/ARCH` note. If the operator does not choose inline or risk, stop and ask again.

### Direct complexity fallback

For a direct `medium` or `complex` story, a missing `REFINE/tasks.md` remains a sizing/checklist issue, not an O1 sibling failure. Hand off to `/split-story-checklist` and resume `sdd-plan` after the stable task ids exist. Do not create, rename, or silently replace the checklist in `sdd-plan`. A direct `trivial` story may use its single PLAN step without that file.

The compact rule is: orchestrated mode requires canonical bodies and required siblings before PLAN; direct mode asks for an inline choice or an explicit risk, while preserving magro paths, provenance, and the existing complexity checklist contract.

---
