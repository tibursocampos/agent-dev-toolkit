# Electron security

Mandatory hardening for BrowserWindow, preload, navigation, and CSP. Preload API shape: `electron-preload.md`. IPC validation: `electron-ipc.md`.

---

## MUST

- Set `contextIsolation: true` on every `BrowserWindow` / `WebContents` that loads app UI.
- Set `nodeIntegration: false` for renderers (and any guest content).
- Enable `sandbox: true` when compatible with the project’s preload (prefer sandbox on for new windows).
- Expose renderer capabilities **only** through `contextBridge.exposeInMainWorld` with a minimal API — never attach full `ipcRenderer`, `require`, or `process`.
- Apply a **Content-Security-Policy** that restricts `script-src` to app bundles; avoid inline scripts unless the existing CSP nonces/hashes already allow a documented exception.
- Block unexpected in-app navigation; open external http(s) via `shell.openExternal` after allow-list checks the project defines.
- Keep secrets out of renderer and preload bundles; load privileged credentials in main (or OS credential stores) only.
- Deny remote code execution patterns: no `eval`, `new Function`, or loading remote HTML/JS with Node powers.

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

```typescript
win.webContents.setWindowOpenHandler(({ url }) => {
  // validate url against allow-list first
  shell.openExternal(url);
  return { action: 'deny' };
});
```

### Security defaults checklist

| Control | Required value / habit |
|---------|------------------------|
| `contextIsolation` | `true` |
| `nodeIntegration` | `false` |
| `sandbox` | `true` when compatible |
| Preload surface | Explicit methods only |
| CSP | Restrict scripts; no remote+Node |
| Navigation | Deny by default; curated externals |

---

## MUST NOT

- Set `nodeIntegration: true` or `contextIsolation: false` without **explicit user/security approval** documented in the change.
- Expose `ipcRenderer` (or a clone of all channels) on `window`.
- Ship `webSecurity: false`, disable CSP in production, or allow `file://` script loads from untrusted trees.
- Run remote content (marketing URLs, untrusted docs) inside a privileged BrowserWindow that has a Node-capable preload.
- Commit API keys, update signing passwords, or notarization credentials.
- Force silent auto-updates without product consent when updater hooks change.

---

## Prefer when matching repo

| Signal | Prefer |
|--------|--------|
| Existing `setWindowOpenHandler` / `will-navigate` | Extend those handlers; do not add a second navigation policy |
| Session-level CSP (`session.defaultSession`) | Match how neighbors apply headers |
| `electron-updater` present | Signed builds + staging channel before production publish |
| Multiple windows | Shared factory that enforces the same `webPreferences` |
| DevTools in prod | Keep disabled unless the product already allows a gated escape hatch |

### Dependency and CVE hygiene

- Pin `electron` via the lockfile; bump deliberately with release notes review.
- Audit native addons when adding packages that touch Node bindings.
- Prefer maintaining one BrowserWindow defaults module over copying `webPreferences` into every call site.

---

## References

- [Electron security tutorial](https://www.electronjs.org/docs/latest/tutorial/security)
- [Context isolation](https://www.electronjs.org/docs/latest/tutorial/context-isolation)
- [Content Security Policy](https://www.electronjs.org/docs/latest/tutorial/security#content-security-policy)
- [Electron security checklist](https://www.electronjs.org/docs/latest/tutorial/security#checklist-security-recommendations)
