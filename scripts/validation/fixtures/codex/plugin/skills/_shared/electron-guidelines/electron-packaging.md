# Electron packaging

Build and distribution with electron-builder, electron-forge, or electron-vite. Signing and updates belong here when the project already ships them. Process layout: `electron-main-renderer.md`.

---

## MUST

- Use the **scripts already defined** in `package.json` (`build`, `dist`, `package`, forge makers) — do not invent a parallel packaging pipeline in a small fix.
- Keep `appId`, `productName`, icons, and extraResources aligned with existing `electron-builder.yml` / `package.json` `build` / forge config.
- Resolve packaged assets with `path.join(__dirname, …)`, `app.getAppPath()`, or project helpers that survive `app.asar`.
- Treat code signing secrets as CI secrets only — never commit certificates, notarization passwords, or Apple/Windows credential files.
- When touching auto-update (`electron-updater` or forge publishers), require **signed builds** and keep user consent / staging channel behavior the product already expects.
- After packaging changes, document smoke: install or run unpacked → launch → exercise changed IPC/feature → quit cleanly.

```bash
npm run build
npm run dist
```

### Common targets

| Platform | Typical artifact |
|----------|------------------|
| Windows | `nsis` / portable |
| macOS | `dmg` / zip (+ notarization when required) |
| Linux | `AppImage` / `deb` / `rpm` per matrix |

---

## MUST NOT

- Hardcode machine-local absolute paths into builder config committed to git.
- Enable `publish` to production from a feature branch without release ownership.
- Force silent updates or remove update UX without product approval.
- Disable asar unpack rules casually when native modules already list `asarUnpack` correctly.
- Commit `dist/` / `out/` binaries when `.gitignore` already excludes them.

---

## Prefer when matching repo

| Signal | Prefer |
|--------|--------|
| electron-builder | Extend `electron-builder.yml` / `build` section; match existing target matrix |
| electron-vite | Verify main + preload + renderer outputs before `dist` |
| electron-forge | Use existing makers/publishers; do not add builder beside forge |
| CI signing | Follow workflow env var names already documented |
| Staging update channel | Test there before production `publish` provider changes |

### Path and asar habits

- Prefer `import.meta.url` / `fileURLToPath` patterns when the main process is ESM and the repo already uses them.
- Put unpackable native binaries where builder config expects them; smoke-load one native call after pack.
- Avoid relative `fs` paths that assume `process.cwd()` equals the asar root.

### Smoke after packaging

1. Install or run the unpacked binary from `dist/` / `out/`.
2. Launch — no blank window; no preload path errors.
3. Exercise the changed feature / IPC.
4. Quit cleanly (macOS: reopen from dock if that is a product path).

### Signing / updates (when in scope)

- Windows Authenticode and macOS notarization: follow team runbooks; keep identities in CI.
- Configure updater `publish` provider only when release infrastructure exists.
- Document rollback (previous channel / version pin) when changing update endpoints.

### Artifact matrix habits

| Concern | Habit |
|---------|--------|
| Icons | Keep platform icon set complete when productName/appId changes |
| Extra resources | Declare in builder config; read via existing main helpers |
| Native modules | Confirm rebuild step runs in CI before pack |
| Version | Prefer single version source (`package.json` / builder `extraMetadata`) already used |

### Failure triage

1. Blank window after pack → preload path / CSP / loadFile vs loadURL mismatch.
2. Missing asset → asar path or `extraResources` not declared.
3. Updater fails → signature / feed URL / channel mismatch (staging first).
4. Native crash → ABI rebuild / `asarUnpack` gap.

Do not “fix” pack failures by disabling sandbox or `webSecurity`.

---

## References

- [Electron application distribution](https://www.electronjs.org/docs/latest/tutorial/application-distribution)
- [electron-builder](https://www.electron.build/)
- [Auto update (electron-updater overview)](https://www.electron.build/auto-update)
- [Code signing overview](https://www.electronjs.org/docs/latest/tutorial/code-signing)
