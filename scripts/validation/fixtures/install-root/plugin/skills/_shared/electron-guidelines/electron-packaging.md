# Electron Packaging

Build and distribution with electron-builder, electron-forge, or electron-vite. Match project tooling.

## Build commands

```bash
npm run build
npm run dist
```

Use scripts defined in `package.json` - do not invent new packaging pipelines.

## electron-builder (common)

- Config in `electron-builder.yml` or `package.json` `build` section.
- Targets: `nsis` (Windows), `dmg` (macOS), `AppImage`/`deb` (Linux) per project matrix.
- `appId`, `productName`, icons under `build/` or `resources/`.

## electron-vite

- Separate builds for main, preload, renderer.
- Verify all three artifacts in `out/` or `dist/` before dist step.

## Assets and paths

- Use `path.join(__dirname, …)` in main for packaged resources.
- Avoid relative paths that break inside `app.asar`.

## Code signing (production)

- Windows: Authenticode; macOS: notarization - follow team docs when signing is required.
- Do not commit certificates or passwords.

## Auto-update cautions

- Configure `publish` provider only when release infrastructure exists.
- Test update on a staging channel before production.
- Never force silent updates without product approval.

## Smoke after packaging

Document in handoff:

1. Install or run unpacked binary.
2. Launch app - no blank window or preload errors in devtools.
3. Exercise changed IPC/feature.
4. Quit cleanly.
