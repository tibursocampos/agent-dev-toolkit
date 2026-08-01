# Expo config and environment

`app.json` / `app.config.*`, env modules, and secrets for Expo / RN apps. Applies when Expo is present; bare RN should still keep secrets out of source and follow existing env patterns.

---

## MUST

- Keep **secrets out of** `app.json`, `app.config.js`/`ts`, committed `.env` files, and client bundles. Use EAS secrets, CI secret stores, or native secure storage for privileged values.
- Treat `EXPO_PUBLIC_*` / public extra config as **public**: anything readable by the app binary can be extracted — never put API private keys there.
- Configure app identity consistently: `name`, `slug`, `scheme`, `ios.bundleIdentifier`, `android.package` — match store / existing releases; do not invent new ids in a small feature.
- Prefer **`app.config.ts`/`js`** dynamic config when the repo already uses it for per-environment `extra`; keep static `app.json` if that is the project standard.
- Document required env vars in README/AGENTS only by **name**, not by value.
- For native permissions (camera, location, notifications), declare plugins / Info.plist / Android permissions through the existing Expo config plugins — do not silently add entitlements without product intent.
- Keep EAS profiles (`eas.json`) aligned with env naming already used in CI.

```ts
// app.config.ts — public flags only in extra / EXPO_PUBLIC_*
import type { ConfigContext, ExpoConfig } from 'expo/config';

export default ({ config }: ConfigContext): ExpoConfig => ({
  ...config,
  name: config.name ?? 'App',
  slug: config.slug ?? 'app',
  extra: {
    apiBaseUrl: process.env.EXPO_PUBLIC_API_BASE_URL,
    appEnv: process.env.EXPO_PUBLIC_APP_ENV,
  },
});
```

---

## MUST NOT

- Commit tokens, private API keys, keystores, or provisioning profiles into the repo.
- Put secrets in `app.config` `extra`, hardcoded strings in source, or checked-in `.env.production` with real credentials.
- Change bundle identifiers / package names casually (breaks upgrades and store listing).
- Add Expo config plugins that rewrite native projects without reading existing plugin list and CNG/prebuild workflow.
- Assume server-only secrets can live in `EXPO_PUBLIC_*` “temporarily.”

---

## Prefer when matching repo

| Signal | Prefer |
|--------|--------|
| EAS Build / Update | `eas.json` profiles; secrets via EAS, not git |
| `expo-constants` + `extra` | Read public config via `Constants.expoConfig?.extra` |
| Multiple flavors (dev/staging/prod) | Existing env files + app.config branching |
| Bare RN without Expo | `.env` + existing native build flavors; same “no secrets in source” rule |
| OTA updates | Channel/branch naming already used by the team |

### Quick audit

- [ ] No secrets in `app.config` / `app.json` / committed env
- [ ] Public env vars clearly named `EXPO_PUBLIC_*` (or project equivalent)
- [ ] Scheme / bundle ids unchanged unless the task explicitly requires it
- [ ] New permissions declared via config plugins with product sign-off
- [ ] `.gitignore` covers local `.env` / credentials files

### Reading config in app code

```ts
import Constants from 'expo-constants';

const apiBaseUrl = Constants.expoConfig?.extra?.apiBaseUrl as string | undefined;
```

Never log secret material; public base URLs are fine.

---

## References

- [Expo app config](https://docs.expo.dev/workflow/configuration/)
- [Environment variables in Expo](https://docs.expo.dev/guides/environment-variables/)
- [EAS secrets](https://docs.expo.dev/eas/environment-variables/)
- [Config plugins](https://docs.expo.dev/config-plugins/introduction/)
