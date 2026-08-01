# Electron IPC

Typed request/response and event channels between main and renderer via preload. Never expose raw `ipcRenderer`. Companion files: `electron-preload.md`, `electron-security.md`.

---

## MUST

- Prefer `ipcMain.handle` + `ipcRenderer.invoke` for **request/response**; use `send` / `on` / `webContents.send` for **fire-and-forget** events.
- **Validate and authorize every payload in main** before touching filesystem, shell, or network — treat renderer input as hostile.
- Centralize channel name strings (constants module or existing enum) so preload and main cannot drift.
- Register handlers once during app ready (or the project’s bootstrap) and remove/replace deliberately on teardown when the suite expects it.
- Return structured results (`null` for cancel, result objects for success) consistent with neighboring handlers — do not throw raw Node errors across IPC without mapping.
- Keep channel privileges least-needed: a UI “read version” channel must not also delete files.

```typescript
// main
import { ipcMain, dialog } from 'electron';
import { IpcChannels } from './ipc-channels';

ipcMain.handle(IpcChannels.DialogOpenFile, async () => {
  const result = await dialog.showOpenDialog({ properties: ['openFile'] });
  return result.canceled ? null : result.filePaths[0];
});
```

```typescript
// preload (excerpt)
openFile: () => ipcRenderer.invoke(IpcChannels.DialogOpenFile),
```

```typescript
// renderer
const file = await window.api.openFile();
```

---

## MUST NOT

- Forward arbitrary channels from renderer (`invoke(channel: string, args)`).
- Trust path strings from the renderer without normalization + allow-list (path traversal).
- Use synchronous IPC (`ipcMain.on` + `event.returnValue`) for new work when async `handle` exists in the project.
- Log secrets, tokens, or full file contents from IPC handlers at info level.
- Duplicate the same handler registration on every window create without guarding against double-register.

---

## Prefer when matching repo

| Signal | Prefer |
|--------|--------|
| Shared `ipc-channels.ts` | Extend the table; update preload typings in the same PR |
| zod / typebox validators | Validate payloads with the existing schema helper |
| Feature folders in main | Colocate handlers with the feature’s main module |
| Event subscriptions | Preload returns an unsubscribe; renderer cleans up on unmount |
| Tests | Unit-test pure validator/handler logic; smoke IPC in packaged app |

### Pattern chooser

| Need | Pattern |
|------|---------|
| Open dialog / read version | `handle` / `invoke` |
| Progress / theme push | `webContents.send` + preload `on` |
| One-shot fire from renderer | `send` / `on` (still validate in main) |
| Stream large data | Prefer temp files or chunked protocols the repo already uses — do not dump huge buffers through IPC casually |

### Handler implementation steps

1. Add channel constant.
2. Implement `ipcMain.handle` with validation.
3. Wrap in preload method (no channel string leakage).
4. Update `Window` typings.
5. Call from renderer; smoke the path.

---

## References

- [IPC tutorial](https://www.electronjs.org/docs/latest/tutorial/ipc)
- [ipcMain](https://www.electronjs.org/docs/latest/api/ipc-main)
- [ipcRenderer](https://www.electronjs.org/docs/latest/api/ipc-renderer)
- [Context isolation](https://www.electronjs.org/docs/latest/tutorial/context-isolation)
