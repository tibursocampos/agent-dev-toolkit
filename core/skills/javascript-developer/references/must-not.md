# javascript-developer — must not

- Paste guideline packs into child prompts (pass scoped **paths** + require **receipt** only)
- Spawn children for **trivial** work (keep **in-parent**)
- Hard-fail when capability `subagents` is `none` or Task is unavailable (use **fallback** **in-parent**)
- Create or route to a separate `node-developer` skill (Node backend stays here)
- Treat Nest as a default skill or guidelines pack (recognition only)
- Drop DOM/`html-css` support in favor of backend-only routing
- Nested `feature/base/...` branches; commit on default integration branches
- Speculative features outside stated acceptance (YAGNI)
- Auto-commit or auto-PR without user request
- Deprecated SDD skill aliases in handoff text - use `sdd-spec`, `sdd-plan`, `sdd-develop`, `commit` only
