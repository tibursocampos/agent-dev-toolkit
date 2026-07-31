# Blip Iframe Messages

Communication between the plugin iframe and the Blip portal via `iframe-message-proxy` and the `blip-iframe` facade.

## Setup

```javascript
import iframe from 'blip-iframe';
import { IframeMessageProxy } from 'iframe-message-proxy';

IframeMessageProxy.listen();
void iframe.heightChange(0);
```

Call once at startup in `src/lib/setup/iframe.js`.

## heightChange

Resize the plugin iframe to fill available portal height:

```javascript
void iframe.heightChange(0);
// or raw proxy:
void IframeMessageProxy.sendMessage({ action: 'heightChange', content: 0 });
```

Call after content layout changes if dynamic height is needed.

## Toast notifications

Use portal-native toasts (not inline BDS toast) for user feedback:

```javascript
// src/lib/iframe-messages/common/showToast.js
import { IframeMessageProxy } from 'iframe-message-proxy';

const sendToastEvent = (toast) => {
  IframeMessageProxy.sendMessage({
    action: 'toast',
    content: toast,
  });
};

const Toast = {
  Success: (message) => sendToastEvent({ type: 'success', message }),
  Error: (message) => sendToastEvent({ type: 'danger', message }),
  Warning: (message) => sendToastEvent({ type: 'warning', message }),
  Info: (message) => sendToastEvent({ type: 'info', message }),
};

export default Toast;
```

Always surface API and auth failures via `Toast.Error` - never silent empty arrays.

## Modal

```javascript
// src/lib/iframe-messages/common/showModal.js
import { IframeMessageProxy } from 'iframe-message-proxy';

export function showModal(content) {
  return IframeMessageProxy.sendMessage({
    action: 'showModal',
    content,
  });
}
```

Follow existing plugin patterns for modal payload shape.

## sendCommand (Blip Router)

For LIME commands (resources, buckets, messaging):

```javascript
const { response } = await IframeMessageProxy.sendMessage({
  action: 'sendCommand',
  content: {
    command: {
      method: 'get',
      uri: `/resources/${resourceKey}`,
    },
    destination: 'lime://postmaster@msging.net', // or from constants
  },
});
```

See `lib/services/resource.js` and `lib/services/command.js` in production plugins.

## getToken

Retrieve JWT for authenticated plugins (Full profile):

```javascript
const { response } = await IframeMessageProxy.sendMessage({
  action: 'getToken',
});
```

Parse JWT payload for user identity. See `auth-and-permissions.md`.

## getCurrentLanguage

Sync i18n with portal language when supported:

```javascript
const { response } = await IframeMessageProxy.sendMessage({
  action: 'getCurrentLanguage',
});
```

Wire into `src/lib/setup/i18n.js`.

## Segment / tracking

Use `segment.prefix` from `appsettings.json` with tracking utilities:

```javascript
// src/lib/utils/track.js
import iframe from 'blip-iframe';

void track('opened');
void track('action-name', { metadata: 'value' });
```

Keep event names consistent and prefixed by plugin segment.

## Action reference

| Action | Purpose |
|--------|---------|
| `heightChange` | Resize iframe |
| `toast` | Portal notification |
| `showModal` | Portal modal |
| `sendCommand` | LIME/Blip Router commands |
| `getToken` | JWT for auth (Full) |
| `getCurrentLanguage` | i18n sync |

## Dev vs production

In local dev outside the portal, iframe messages may fail. Use `isDev` guards with mocks - never call real `getToken` without the portal context.
