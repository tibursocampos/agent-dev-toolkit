# Electron delivery checklist

Use before opening a pull request for Electron (main / preload / renderer / packaging) work. Match the project’s builder (electron-vite, electron-builder, forge).

---

## Preparation

- [ ] `AGENTS.md` / README reviewed; main/preload/renderer entries identified
- [ ] PLAN step (if applicable) understood; acceptance criteria clear
- [ ] Loaded only needed files from this pack + renderer stack guidelines
- [ ] DESIGN-BRIEF consulted when present (do not reinterpret visuals)

---

## Branching

- [ ] Working branch: `feature/<slug>` or `feat/<id>-<slug>`
- [ ] Based on the correct default branch (`main` / `develop` / team default)

---

## Security (blocking)

- [ ] `contextIsolation: true`
- [ ] `nodeIntegration: false`
- [ ] `sandbox: true` when compatible with preload
- [ ] No full `ipcRenderer` / `require` / `process` on `window`
- [ ] CSP / navigation handlers reviewed for touched windows (`electron-security.md`)
- [ ] No remote content + Node privileges

---

## Main, preload, IPC

- [ ] Process roles respected (`electron-main-renderer.md`)
- [ ] Preload API minimal + typed (`electron-preload.md`)
- [ ] Channels constantized; payloads validated in main (`electron-ipc.md`)
- [ ] Dev vs production load paths unchanged unless required

---

## Packaging (if touched)

- [ ] Existing npm scripts / builder config extended — no parallel pipeline
- [ ] Asar-safe paths; no secrets in repo (`electron-packaging.md`)
- [ ] Updater/signing changes gated on product + staging expectations

---

## Validate

```bash
npm run build
```

(and `npm test` / project-equivalent when present)

- [ ] Manual smoke: app launches; changed IPC/feature works; clean quit
- [ ] Identifiers/comments in **English**
- [ ] `/commit` offered — do not auto-commit

---

## Prefer when matching repo

| Signal | Action |
|--------|--------|
| React / Vue in renderer | Load stack guidelines for UI only; stay on `electron-developer` |
| electron-vite | Confirm three artifacts (main/preload/renderer) before dist |
| DESIGN-BRIEF present | Treat as acceptance; do not reinterpret visuals |

### Pack map (load only what you need)

| Concern | File |
|---------|------|
| Security / CSP / navigation | `electron-security.md` |
| Main / renderer roles | `electron-main-renderer.md` |
| Preload / contextBridge | `electron-preload.md` |
| IPC channels | `electron-ipc.md` |
| Build / sign / update | `electron-packaging.md` |

---

## References

- Pack files in this folder
- [Electron security](https://www.electronjs.org/docs/latest/tutorial/security)
- [IPC tutorial](https://www.electronjs.org/docs/latest/tutorial/ipc)
- Hub: `frontend-guidelines/frontend-practices.md`
