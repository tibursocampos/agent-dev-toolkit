## Must not

- Paste guideline packs into child prompts (pass scoped **paths** + require **receipt** only)
- Spawn children for **trivial** work (keep **in-parent**)
- Hard-fail when capability `subagents` is `none` or Task is unavailable (use **fallback** **in-parent**)
- Auto-commit or auto-PR
- Leave AI traces in code comments or identifiers (see `ai-stealth.mdc`)
- Delegate when a clear stack match exists
- Dump full memory-bank / PRD into child prompts or preload all stack guideline packs
