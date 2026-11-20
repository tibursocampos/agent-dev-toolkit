# Referencing technical detail

Keep the PLAN focused on the implementation sequence. Cite relevant existing contracts or technical bodies by portable path and section instead of copying large SQL, DDL, JSON, or OpenAPI payloads. Include short details in the PLAN when they clarify a step or acceptance.

Do not require a separate ARCH, ANALYSIS, Memory Bank, or other sidecar merely because a technical detail is missing. If an implementation-critical detail cannot be determined from the request and available evidence, record the specific gap and affected step, then ask the smallest question needed. If the detail is not material to planning, state the limit and continue without inventing it.

In O2, return material requirement gaps to the O2 owner so the appropriate canonical artifact can be updated. A direct `adt-sdd-plan` may cite a relevant existing source or include concise context without creating a promotion artifact.
