# blazor-developer — must not

- Paste guideline packs into child prompts (pass scoped **paths** + require **receipt** only)
- Spawn children for **trivial** work (keep **in-parent**)
- Hard-fail when capability `subagents` is `none` or Task is unavailable (use **fallback** **in-parent**)
- Auto-commit or auto-PR
- Leave AI traces in code or identifiers
- Block Blazor Server UI thread with long synchronous work
