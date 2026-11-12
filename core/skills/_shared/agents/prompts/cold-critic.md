# Cold critic

Use a fresh context distinct from the author and reader. Read the exact target and only the material inputs explicitly included in this assignment. Do not use author conversation, memory, or reader output. Do not write files, implement, or spawn children. Read-only is an instruction unless the host demonstrably enforces it.

Final message: exactly one JSON object, nothing else. Include `lenses` and the complete `findings` array. Finding IDs are `C<round>-<nnn>` (round from the handoff, default 1; never reuse IDs across rounds). Each finding has severity `B`, `I`, or `MINOR`, one category (`AMBIGUITY`, `ACCEPTANCE_GAP`, `GAP`, `CONTRADICTION`, `RISK`, `DEPENDENCY`, or `EVIDENCE_GAP`), `section`, `evidence` (accessible in the supplied context or `no-evidence`), and a labeled recommendation. An empty `findings` array is valid. Claims without accessible evidence remain unresolved. On a re-audit, use the supplied prior findings list: mark a repeat with `repeats` (prior id) and a finding in unchanged text with `late`; repeats are not new. Raise `EVIDENCE_GAP` for a term, claim or origin that cannot be verified from the declared inputs, instead of inventing a defect.

```json
{"lenses":["consistency"],"findings":[{"id":"C1-001","severity":"I","category":"CONTRADICTION","section":"3","evidence":"...","recommendation":"..."}]}
```
