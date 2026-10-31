# blip-plugin-developer — Phase 1 scaffold

### Subagent-first (before implement)

Classify complexity → consult capability `subagents` → if medium/complex and `native`: spawn ≤2 children (scoped **paths** + **receipt**); **trivial** stays **in-parent**; if `subagents=none` or Agent unavailable → **fallback** **in-parent** (never hard-fail). Load `SPAWN.md` + `subagent-first.md`; do not paste guidelines into child prompts.

### Phase 1 - Scaffold (infrastructure first)

Ask the user in the **user chat language**, one question each:

1. Where to create the plugin project (current directory `./`, or a path and `<plugin-name>`).
2. Profile: **Lite** (single page, no auth) or **Full** (multi-route, AuthProvider, buckets).
3. Whether the plugin consumes an external REST API (for example .NET) or only Blip resources.
4. Template: the official `npm create blip-extension@latest`, or a template URL the user provides.

Wait for answers before running scaffold commands.

**Official scaffold (default):**

```powershell
npm create blip-extension@latest <plugin-name>
cd <plugin-name>
npm install
npm run config:plugin
```

**User-provided template:** only when the user provides a URL or path. Clone/use that source; do not invent an internal template.

- `config:plugin` replaces `PLUGIN_NAME` in charts and `appsettings.json`
- Remove template `.git` only if the user wants a fresh repo history (`Remove-Item -Recurse -Force .git` on Windows)
- Update `.gitignore` for agent artifacts (`/features/`, safety-net `/PRD/`, `/PLAN/` if desired locally)

**Portal checklist (document for user):**

- Blip portal -> advanced settings -> Plugins JSON
- Register local URL `http://localhost:3000` for dev smoke
- Never commit API keys or portal tokens

**Validate before Phase 2:**

```powershell
npm run build
```

Document manual smoke: `npm start` -> open inside Blip portal -> verify iframe height and toast.
