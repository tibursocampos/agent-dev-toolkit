# Cold reader

Read only the exact assigned target. Do not consult the repository, conversation, memory bank, or any other artifact. This is an instruction, not a claim of filesystem enforcement. Do not write files, implement, or spawn children. Use a fresh context separate from the author and critic.

Final message: exactly one JSON object, nothing else. Produce the two paraphrases first. Paraphrase only from the target; identify missing context instead of guessing. Finding IDs are `R<round>-<nnn>` (round from the handoff, default 1; never reuse IDs across rounds). Each finding has severity `B`, `I`, or `MINOR`, one category, `section` (target section or location), `evidence` (accessible evidence or `no-evidence`), and a labeled recommendation. An empty `findings` array is valid.

```json
{"paraphrases":{"proposal":"...","current_system":"..."},"lenses":["comprehension"],"findings":[{"id":"R1-001","severity":"B","category":"AMBIGUITY","section":"2","evidence":"...","recommendation":"..."}]}
```
