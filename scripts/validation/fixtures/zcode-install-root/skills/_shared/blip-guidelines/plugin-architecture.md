# Blip Plugin Architecture

Standards for Blip React plugins using **Lite** and **Full** complexity profiles (technical criteria only).

## Directory layout

```
src/
  index.{js,jsx}              # bootstrap: imports lib/setup/* then renders root
  App.jsx / Routes.jsx        # React Router v6
  config/appsettings.json     # blip, language, segment.prefix, api
  lib/setup/                  # blip-ds, fonts, i18n, iframe, root
  lib/services/               # resource.js, command.js, domain services
  lib/iframe-messages/        # showToast, showModal wrappers
  lib/constants.js
  assets/locales/{en,es,pt}/
charts/{plugin-name}/         # Helm (when deploying to K8s)
Dockerfile
tailwind.config.js            # tailwind-blip-ds plugin
cypress/                      # component tests + nyc coverage
```

CI files (`.github/workflows/`, `azure-pipelines.yml`, etc.) appear when present — detect; do not assume one vendor. See `deploy-and-ci.md`.

Do not create parallel trees (e.g. `src/component/` and `src/components/`). Follow the scaffold layout.

## Global setup (`src/lib/setup/`)

Keep `index.js` thin. Import setup modules in order:

1. `blip-ds.js` - register web components
2. `fonts.js` - Nunito Sans via `@fontsource/nunito-sans`
3. `i18n.js` - sync language with portal
4. `iframe.js` - listen + heightChange
5. `root.js` - render React tree

```javascript
// src/lib/setup/blip-ds.js
import { applyPolyfills, defineCustomElements } from 'blip-ds/loader';

void applyPolyfills().then(() => defineCustomElements(window));
```

## Iframe initialization

Prefer `blip-iframe` facade when available; fallback to raw proxy:

```javascript
import iframe from 'blip-iframe';
import { IframeMessageProxy } from 'iframe-message-proxy';

IframeMessageProxy.listen();
void iframe.heightChange(0);
```

Setting height to `0` makes the iframe expand to 100% of remaining portal height.

See `blip-iframe-messages.md` for toast, modal, and command actions.

## Routing

Use **React Router v6** with `createBrowserRouter` and `RouterProvider`:

- Root `Layout` wraps all routes
- `ErrorPage` for fallbacks
- **Full profile:** wrap routes with `AuthProvider` (see `auth-and-permissions.md`)
- **Lite profile:** single route, no auth wrapper

## Internationalization

Use `react-i18next` + `i18next`. Locale files under `assets/locales/{en,es,pt}/`.

Sync language with the Blip portal via iframe messages (`getCurrentLanguage` or portal config in `appsettings.json`).

Default language in `config/appsettings.json`:

```json
{
  "language": {
    "default": "pt",
    "debug": false
  }
}
```

## Blip resources vs external API

| Pattern | When | Service |
|---------|------|---------|
| Blip Router resources | Config stored in Blip | `lib/services/resource.js` via `sendCommand` |
| External REST API | Custom backend (.NET, etc.) | HTTP client + `external-api-integration.md` |

Do not mix both patterns in the same service module.

## Local development

Use `lib/utils/isDev.js` to branch behavior:

- **Dev:** mock resources in `localStorage`, stub token/user
- **Prod:** iframe messages only

Never ship dev mocks behind a loose env check in production builds.

## Testing

Use **Cypress component tests** (not Jest DOM) because:

- JSDOM does not support BDS web components
- Cypress renders real components with coverage via `@cypress/code-coverage` and `nyc`

```bash
npm run test:cypress
npm run test:coverage
npm run build
```

## appsettings.json

Key sections:

| Key | Purpose |
|-----|---------|
| `blip.domain`, `blip.url` | Portal identity |
| `segment.prefix` | Analytics segment (must match plugin name after `config:plugin`) |
| `api.url`, `api.key` | External API (leave empty in repo; inject at deploy) |
| `language.default` | Default locale |

Never commit real API keys or tokens.
