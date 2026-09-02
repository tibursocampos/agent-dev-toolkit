# python-developer — must not

- Paste guideline packs into child prompts (pass scoped **paths** + require **receipt** only)
- Spawn children for **trivial** work (keep **in-parent**)
- Hard-fail when capability `subagents` is `none` or Task is unavailable (use **fallback** **in-parent**)
- Treat the skill as FastAPI-only (Flask remains in scope)
- Nested `feature/base/...` branches; commit on default integration branches
- Speculative features outside stated acceptance (YAGNI)
- Auto-commit or auto-PR without user request
- Deprecated SDD skill aliases in handoff text - use `sdd-spec`, `sdd-plan`, `sdd-develop`, `commit` only
