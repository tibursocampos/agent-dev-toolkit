# electron-developer — must not

- Paste guideline packs into child prompts (pass scoped **paths** + require **receipt** only)
- Spawn children for **trivial** work (keep **in-parent**)
- Hard-fail when capability `subagents` is `none` or Task is unavailable (use **fallback** **in-parent**)
- Enable `nodeIntegration: true` in renderer without explicit user approval
- Expose raw `ipcRenderer` on `window` without contextBridge
- Auto-commit or auto-PR
- Leave AI traces in code or identifiers
