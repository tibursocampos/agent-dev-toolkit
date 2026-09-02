# blip-plugin-developer — Phase 1 scaffold

### Subagent-first (before implement)

Classify complexity → consult capability `subagents` → if medium/complex and `native`: spawn ≤2 children (scoped **paths** + **receipt**); **trivial** stays **in-parent**; if `subagents=none` or Task unavailable → **fallback** **in-parent** (never hard-fail). Load `SPAWN.md` + `subagent-first.md`; do not paste guidelines into child prompts.

### Phase 1 - Scaffold (infrastructure first)

Ask the user **(pt-BR)**:

1. "Onde deseja criar o projeto do plugin? (diretório atual `./` ou informe caminho e nome `<plugin-name>`)"
2. "Qual perfil? **Lite** (página única, sem auth) ou **Full** (multi-rota, AuthProvider, buckets)?"
3. "O plugin consome API REST externa (ex.: .NET) ou apenas resources Blip?"
4. "Template: `npm create blip-extension@latest` (oficial) ou URL de template fornecida por você?"

Wait for answers before running scaffold commands.

**Official scaffold (default):**

```powershell
npm create blip-extension@latest <plugin-name>
cd <plugin-name>
npm install
npm run config:plugin
```

**User-provided template:** only when the user supplies a URL or path. Clone/use that source; do not invent an internal template.

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
