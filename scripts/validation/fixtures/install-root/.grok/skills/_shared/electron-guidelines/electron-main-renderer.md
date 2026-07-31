# Electron Main and Renderer

Process separation and IPC patterns. Match project layout (`electron/`, `src/main/`, `electron-vite` conventions).

## Process roles

| Process | Responsibility |
|---------|----------------|
| **Main** | App lifecycle, native menus, `BrowserWindow`, system dialogs, privileged APIs |
| **Preload** | Bridge: expose safe APIs to renderer via `contextBridge` |
| **Renderer** | UI (HTML/CSS/JS/React/Vue) - untrusted; no direct Node access |

## BrowserWindow defaults

```typescript
const win = new BrowserWindow({
  webPreferences: {
    preload: path.join(__dirname, 'preload.js'),
    contextIsolation: true,
    nodeIntegration: false,
    sandbox: true,
  },
});
```

Match project defaults; never weaken security without explicit approval.

## IPC patterns

**Main** - register handlers:

```typescript
ipcMain.handle('dialog:openFile', async () => {
  const result = await dialog.showOpenDialog({ properties: ['openFile'] });
  return result.canceled ? null : result.filePaths[0];
});
```

**Preload** - expose typed API:

```typescript
contextBridge.exposeInMainWorld('api', {
  openFile: () => ipcRenderer.invoke('dialog:openFile'),
});
```

**Renderer** - consume `window.api` (declare types in `global.d.ts`).

## Conventions

- Use `ipcMain.handle` / `ipcRenderer.invoke` for request/response; `send`/`on` for fire-and-forget events.
- Validate all IPC payloads in main process.
- Keep preload script minimal - no business logic.

## electron-vite / electron-builder

Follow existing entry config (`main`, `preload`, `renderer` in `vite.config` or package.json `main` field).

## Dev vs production

- Load `loadURL` (dev server) vs `loadFile` (packaged) per project scripts.
- Do not hardcode dev server URLs in production paths.
