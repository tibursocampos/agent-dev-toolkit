# electron-developer — execute flow

Read this file for procedural detail. Do not dump stack guideline packs into chat or child prompts — lazy-load **one** guideline file when that surface is in scope.

### Subagent-first (before implement)

Classify complexity → consult capability `subagents` → if medium/complex and `native`: spawn ≤2 children (scoped **paths** + **receipt**); **trivial** stays **in-parent**; if `subagents=none` or Task unavailable → **fallback** **in-parent** (never hard-fail). Load `SPAWN.md` + `subagent-first.md`; do not paste guidelines into child prompts.

### 0. Workspace

Confirm Electron project (`electron`, `electron-builder`, or `electron-vite` in `package.json`). Identify main/preload/renderer entry points.

### 1. Guidelines

Load Electron + renderer guidelines for this task. Review security defaults before IPC changes.

### 2. Branch

Use `feature/<slug>` or `feat/<id>`. Never commit on `main`/`master`/`develop`.

### 3. Micro-plan

Define 3-7 concrete tasks; checkpoint context at >= 40%.

### 4. Implement

Main/preload/renderer separation, typed IPC, contextIsolation. Match existing electron-vite or electron-builder layout.

### 5. Tests

Unit tests for pure modules; manual smoke: app launches, changed flow works.

### 6. Validate

```bash
npm run build
```

Document smoke steps in chat (launch app, exercise changed feature).

### 7. Handoff

Offer `/commit`. Do not commit automatically.
