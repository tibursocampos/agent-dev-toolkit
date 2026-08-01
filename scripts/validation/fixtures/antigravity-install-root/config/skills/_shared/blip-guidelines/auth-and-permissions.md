# Auth and Permissions (Full profile)

JWT token parsing, bucket-based permissions, and `AuthProvider`. **Skip this file for Lite profile plugins.**

## When to use

Apply when the plugin needs:

- User identity from the Blip portal
- Role-based UI (read-only vs admin)
- Permission buckets stored in Blip Router

**Lite** plugins (single route, no auth) do not use this flow - do not add `AuthProvider` unless requirements demand Full profile.

## getToken flow

```javascript
// src/lib/services/account.js
import { Buffer } from 'buffer';
import { IframeMessageProxy } from 'iframe-message-proxy';

function parseJwt(token) {
  return JSON.parse(Buffer.from(token.split('.')[1], 'base64').toString());
}

const parseTokenAsync = async () => {
  const { response } = await IframeMessageProxy.sendMessage({
    action: 'getToken',
  });
  const user = parseJwt(response);
  return { isValid: true, response: user };
};
```

In dev (`isDev`), return a stub user from `constants.js` - never hardcode production emails in committed code.

## Bucket permissions

Load authorized users from a Blip bucket:

```javascript
const response = await sendCommandAsync({
  method: 'get',
  to: 'postmaster@msging.net',
  uri: `/buckets/${CONSTANTS.UsersBucketKey}`,
});
```

Match bucket user email to JWT email and read permission map:

```javascript
const userBucket = bucket.response.users.find(
  (u) => u.email === parsedToken.response.email
);
const feature = userBucket?.permissions['featureKey'];
// feature: 'read' | 'admin' | undefined
```

Define bucket keys in `lib/constants.js` - never inline bucket URIs in components.

## AuthProvider

Wrap routes with context provider:

```jsx
// src/Routes.jsx
import { AuthProvider } from './shared/hooks/useAuth';

<AuthProvider>
  <RouterProvider router={router} />
</AuthProvider>
```

```jsx
// src/shared/hooks/useAuth.jsx
export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [permissions, setPermissions] = useState(defaultPermissions);

  useEffect(() => {
    (async () => {
      const parsedToken = await parseTokenAsync();
      const bucket = await getUsersAsync();
      // merge token + bucket -> setUser, setPermissions
    })();
  }, []);

  return (
    <AuthContext.Provider value={{ user, permissions }}>
      {children}
    </AuthContext.Provider>
  );
};
```

## Permission gates in UI

```jsx
const { featurePermissions } = useAuth();

if (!featurePermissions.isAuthorized) {
  return <UnauthorizedPage />;
}

<BdsButton disabled={featurePermissions.isReadOnly}>Save</BdsButton>
```

Hide destructive actions when `isReadOnly`; show admin-only routes when `isAdmin`.

## External API auth

When calling a REST backend, pass the Blip token (or a derived API key) in headers per the API contract — often:

```
Authorization: Key <token>
```

See `external-api-integration.md` for header format and error handling.

## Security rules

- Never commit JWTs, API keys, or bucket contents
- Never log full tokens
- Fail closed: unauthorized users see an explicit message, not empty data
- Do not bypass `AuthProvider` with ad-hoc token reads in leaf components
