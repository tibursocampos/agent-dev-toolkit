# electron-developer — execute flow

Read this file for procedural detail. Do not dump stack guideline packs into chat or child prompts — lazy-load **one** guideline file when that surface is in scope.

### Subagent-first (before implement)

Classify complexity → consult capability `subagents` → if medium/complex and `native`: spawn ≤2 children (scoped **paths** + **receipt**); **trivial** stays **in-parent**; if `subagents=none` or Agent unavailable → **fallback** **in-parent** (never hard-fail). Load `SPAWN.md` + `subagent-first.md`; do not paste guidelines into child prompts.

### 0. Workspace

Confirm Electron project (`electron`, `electron-builder`, or `electron-vite` in `package.json`). Identify main/preload/renderer entry points.

### 1. Guidelines

Load Electron + renderer guidelines for this task. Review security defaults before IPC changes.

### 2. Branch

Use `feature/<slug>` or `feat/<id>-<slug>`. Never commit on `main`/`master`/`develop`.

### 3. Micro-plan

Checkpoint durable workflow progress at the workflow-defined boundaries; context usage does not add a stop gate.

### 4. Implement

Discover architectural patterns in the touched area first. Follow `structure-and-quality.md` §1: an operator order and the established project style outrank the toolkit style bar. Do not restyle existing members without an explicit yes. On greenfield / no clear comment-language mirror, ask before writing narrative comments/docs (identifiers stay English).

Main/preload/renderer separation, typed IPC, contextIsolation. Match existing electron-vite or electron-builder layout.

### 5. Tests

Use the project's configured test runner and package-manager scripts for pure modules; preserve its existing test setup. If no test baseline exists, choose a minimal runner appropriate to the change. Manual smoke: app launches, changed flow works.

### 6. Validate

```bash
<configured-package-manager> run <declared-build-script>
```

Inspect the lockfile and `package.json` scripts first. If no build script is declared, use the documented Electron build command for the detected setup; do not assume npm or add a script solely to satisfy this checklist. Document smoke steps in chat (launch app, exercise changed feature).

### 7. Handoff

Offer `/commit`. Do not commit automatically.
