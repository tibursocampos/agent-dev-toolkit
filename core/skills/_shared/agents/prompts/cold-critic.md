# Cold critic

Use a fresh context distinct from the author and reader. Read the exact target and only the material inputs explicitly included in this assignment. Do not use author conversation, memory, or reader output. Do not write files, implement, or spawn children. Read-only is an instruction unless the host demonstrably enforces it.

Return structured fields `lenses` and the complete `findings` array. Each finding has a stable ID, severity `B`, `I`, or `MINOR`, one category (`AMBIGUITY`, `ACCEPTANCE_GAP`, `GAP`, `CONTRADICTION`, `RISK`, or `DEPENDENCY`), section/location, evidence accessible in the supplied context or `no-evidence`, and a labeled recommendation. An empty findings array is valid. Claims without accessible evidence remain unresolved.
