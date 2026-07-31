# Electron main and renderer

Process roles, BrowserWindow lifecycle, and entry wiring. Detailed preload: `electron-preload.md`. IPC channels: `electron-ipc.md`. Security defaults: `electron-security.md`.

---

## MUST

- Keep **main**, **preload**, and **renderer** responsibilities separated — match `electron/`, `src/main/`, or electron-vite entry layout already in the repo.
- Create windows through the project’s window factory (or existing pattern) so `webPreferences` stay consistent (`contextIsolation: true`, `nodeIntegration: false`, sandbox when possible).
- Load UI with the project’s **dev vs production** strategy (`loadURL` for the Vite/webpack dev server; `loadFile` / custom protocol for packaged builds) — do not hardcode localhost URLs into production paths.
- Put privileged work (dialogs, filesystem, OS integration, secrets) in **main** only.
- Treat the renderer as untrusted UI (HTML/CSS/JS/React/Vue): no direct Node access.
- Register app lifecycle handlers (`ready`, `window-all-closed`, `activate`) the way the existing main entry does (especially macOS dock behavior).

### Process roles

| Process | Responsibility |
|---------|----------------|
| **Main** | App lifecycle, menus, `BrowserWindow`, system dialogs, privileged APIs |
| **Preload** | Bridge: expose a minimal safe API via `contextBridge` |
| **Renderer** | UI only — consume `window.api` (or project name); never `require('electron')` |

```typescript
const win = new BrowserWindow({
  webPreferences: {
    preload: path.join(__dirname, 'preload.js'),
    contextIsolation: true,
    nodeIntegration: false,
    sandbox: true,
  },
});

if (isDev) {
  await win.loadURL(process.env.VITE_DEV_SERVER_URL!);
} else {
  await win.loadFile(path.join(__dirname, '../renderer/index.html'));
}
```

---

## MUST NOT

- Import renderer React/Vue application modules into main (or the reverse) when the build already splits bundles.
- Bypass preload by enabling Node in the renderer for convenience.
- Spawn unbounded BrowserWindows without reusing the project’s single-instance / focus-existing-window behavior when present.
- Leave bare `openExternal` on every `window.open` without the security handlers in `electron-security.md`.
- Commit environment-specific absolute paths for asar resources — use `path.join(__dirname, …)` / `app.getPath` patterns already in main.

---

## Prefer when matching repo

| Signal | Prefer |
|--------|--------|
| electron-vite | Respect `main` / `preload` / `renderer` inputs in Vite config |
| electron-forge / webpack | Extend existing main entry and forge makers |
| React / Vue renderer | Load stack guidelines for UI only; stay in `electron-developer` identity |
| Custom protocol (`app://`) | Register once in main; keep CSP aligned |
| Tray / deep links | Follow existing second-instance and protocol handlers |

### Dev vs production checklist

1. Confirm `isDev` (or equivalent) detection matches package scripts.
2. Verify preload path resolves under both `electron .` and packaged asar.
3. Smoke: cold start, reload, open external link, quit (macOS: reopen from dock if applicable).

### Tooling notes

- Follow `package.json` `main` field and existing build scripts — do not invent a parallel packaging pipeline in a small fix (`electron-packaging.md`).
- When adding native modules, rebuild for Electron’s ABI using the project’s already chosen tool (`electron-rebuild`, `@electron/rebuild`, forge hooks).

---

## References

- [Electron process model](https://www.electronjs.org/docs/latest/tutorial/process-model)
- [Using Preload Scripts](https://www.electronjs.org/docs/latest/tutorial/tutorial-preload)
- [BrowserWindow](https://www.electronjs.org/docs/latest/api/browser-window)
