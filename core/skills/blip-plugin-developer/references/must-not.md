# blip-plugin-developer — must not

- Paste guideline packs into child prompts (pass scoped **paths** + require **receipt** only)
- Spawn children for **trivial** work (keep **in-parent**)
- Hard-fail when capability `subagents` is `none` or Task is unavailable (use **fallback** **in-parent**)
- Use `cra-template-blip-plugin` (microbundle) as scaffold default
- Scaffold from any unofficial template URL unless the user provides it
- Skip `npm run config:plugin`
- Skip `sdd-spec` when starting SDD from scratch
- Hand off to Antigravity-only personas
- Mix backend API implementation into the plugin scaffold session
- Prefer org-only CI templates over what the repo already uses
