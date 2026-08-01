# Electron Security

Mandatory checks before shipping or merging IPC/window changes.

## Renderer hardening

- `contextIsolation: true`
- `nodeIntegration: false`
- `sandbox: true` when compatible with preload
- No `eval`, `new Function`, or remote HTML without sanitization

## Preload

- Expose only required methods via `contextBridge.exposeInMainWorld`.
- Do not expose full `ipcRenderer`, `require`, or `process` to renderer.
- Type the exposed API in a shared `preload.d.ts` or `global.d.ts`.

## Navigation and external links

```typescript
win.webContents.setWindowOpenHandler(({ url }) => {
  shell.openExternal(url);
  return { action: 'deny' };
});
```

- Block navigation to unexpected origins in packaged apps.
- Use `shell.openExternal` for http(s) links - never `window.open` to arbitrary URLs in renderer.

## Content Security Policy

- Apply CSP in renderer HTML or session when the project supports it.
- Restrict `script-src` to app bundles; avoid inline scripts.

## Dependencies

- Audit native modules and electron version for known CVEs when adding packages.
- Pin `electron` version per project lockfile.

## Secrets

- Never store API keys in renderer or preload.
- Use OS credential stores or main-process env loaded at startup - not bundled in renderer JS.

## Auto-update

- `electron-updater` only with signed builds and explicit user consent for install.
- Document rollback plan when touching update channel config.
