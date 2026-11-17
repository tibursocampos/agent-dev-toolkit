# Optional Memory Bank context

O1 has no Memory Bank gate. Do not run `memory-bank-init`, create a bank, or
refresh one solely to analyze a request.

When a bank already exists and relevant material can answer a concrete
question, resolve its root using `STORAGE.md` and `STORAGE-RESOLUTION.md`, then
read only the named relevant files. Keep evidence selective; do not dump the
whole bank into the O1 context or duplicate it in FEATURE/STORY.

If the user explicitly asks to create or refresh a Memory Bank, route through
`memory-bank-init` as a separately requested task. That operation does not
become a prerequisite for O1. Do not write bank path/status fields into
CONTINUITY as an O1 requirement.
