# Electron preload

`contextBridge` API design, typing, and sandbox-friendly preload scripts. Security invariants: `electron-security.md`. Channel handlers: `electron-ipc.md`.

---

## MUST

- Use `contextBridge.exposeInMainWorld(apiKey, api)` as the **only** way to publish main-world APIs.
- Expose **narrow, intention-revealing methods** (e.g. `openFile`, `getAppVersion`) — not generic `invoke(channel, …)` pass-throughs that re-open the entire IPC surface.
- Keep `ipcRenderer` usage **inside** the preload module only; never assign `ipcRenderer` to `window`.
- Type the exposed API in `preload.d.ts` / `global.d.ts` (or the project’s shared types package) so the renderer compiles against a contract.
- Keep preload free of business logic and large dependencies — forward to main via `invoke` / `send`.
- Compatible with `sandbox: true` whenever the project can run sandboxed preloads (prefer enabling sandbox on windows that use this preload).

```typescript
import { contextBridge, ipcRenderer } from 'electron';

contextBridge.exposeInMainWorld('api', {
  openFile: (): Promise<string | null> => ipcRenderer.invoke('dialog:openFile'),
  onThemeChanged: (handler: (theme: string) => void) => {
    const listener = (_event: Electron.IpcRendererEvent, theme: string) => handler(theme);
    ipcRenderer.on('theme:changed', listener);
    return () => ipcRenderer.removeListener('theme:changed', listener);
  },
});
```

```typescript
// global.d.ts
export interface DesktopApi {
  openFile: () => Promise<string | null>;
  onThemeChanged: (handler: (theme: string) => void) => () => void;
}

declare global {
  interface Window {
    api: DesktopApi;
  }
}
```

---

## MUST NOT

- Expose full `ipcRenderer`, `ipcRenderer.invoke.bind(ipcRenderer)`, `require`, `process`, or `electron` on the main world.
- Accept arbitrary channel strings from the renderer (`invoke(channel: string, …)`).
- Perform privileged filesystem or credential work in preload — do it in main after IPC.
- Import renderer UI frameworks into preload.
- Leave event listeners registered without a dispose/unsubscribe function when the API subscribes to main events.

---

## Prefer when matching repo

| Signal | Prefer |
|--------|--------|
| Existing `window.api` / `window.desktop` name | Keep the same global key |
| electron-vite preload entry | Build preload as its own input; do not bundle with renderer |
| Channel constants module | Import shared channel names; do not hardcode divergent strings |
| Unsubscribe patterns | Return disposer functions as siblings already do |
| Multiple preloads | One preload per window class; do not share a mega-API across trust levels |

### Preload review questions

1. Can any method be removed without breaking the current UI task?
2. Are all channels allow-listed in main (`electron-ipc.md`)?
3. Do TypeScript declarations match the runtime object 1:1?
4. Does sandbox still boot with this preload?

### Build wiring

- Ensure packaged path to the preload script is correct under asar (`path.join(__dirname, 'preload.js')` or project helper).
- After changing preload, smoke-launch and confirm DevTools shows `window.api` (or project key) without Node globals.

---

## References

- [Context isolation](https://www.electronjs.org/docs/latest/tutorial/context-isolation)
- [Tutorial: Preload](https://www.electronjs.org/docs/latest/tutorial/tutorial-preload)
- [contextBridge API](https://www.electronjs.org/docs/latest/api/context-bridge)
