# External API Integration

Patterns for Blip plugins that call REST backends (not Blip Router resources).

## When to use

- Plugin UI talks to a custom .NET/Node/other REST API
- Backend repo is **separate** from the plugin repo
- Use `/dotnet-developer` (or the matching backend skill) for backend work; `react-developer` + this guideline for the plugin client

For Blip-native storage only, use `lib/services/resource.js` instead.

## Response envelopes

Many backends wrap payloads. Common .NET-style envelope:

```json
{
  "value": { ... },
  "statusCode": 200
}
```

Other APIs may return the entity at the root, or `{ data, errors }`, or Problem Details (`application/problem+json`). **Read the contract** (OpenAPI) and unwrap once in the client.

**Wrong:**

```javascript
const data = response.data; // misses .value when the API uses an envelope
```

**Correct (envelope example):**

```javascript
const result = response.data;
if (result.statusCode !== 200 || !result.value) {
  throw new ApiError(result);
}
const payload = result.value;
```

For paginated search (typical shape):

```javascript
const { items, totalCount, page, pageSize } = result.value;
```

Centralize unwrap logic in one API factory/service - do not repeat in every component.

## Authorization header

Match the backend contract. Common Blip-adjacent APIs use:

```
Authorization: Key <token>
```

Others use `Bearer <jwt>`, cookies, or custom headers. **Wrong:** assume Bearer or Key without verifying OpenAPI / controller filters.

Obtain token via `getToken` iframe message (Full profile) or from `appsettings.json` in dev only.

## Required headers

| Header | When |
|--------|------|
| Auth header per contract | All authenticated routes |
| Scope / tenant header (if API defines) | Multi-tenant or campaign-scoped routes |
| `Content-Type: application/json` | POST/PUT/PATCH bodies |
| Correlation ID (if API defines) | Pass through for support/debug |

Read header requirements from OpenAPI or controller filters - do not guess.

## Status and enum mapping

APIs often return numeric filters and localized display strings. Map in a single constants module:

```javascript
export const ENTITY_STATUS = {
  Available: 0,
  Reserved: 1,
  Claimed: 2,
};

export const ENTITY_STATUS_LABEL = {
  [ENTITY_STATUS.Available]: 'Disponível',
  [ENTITY_STATUS.Reserved]: 'Reservado',
  [ENTITY_STATUS.Claimed]: 'Resgatado',
};
```

**Wrong:** hardcode English labels when the API returns another locale, or mix filter ints with display strings in components.

## Error handling

**Wrong:**

```javascript
try {
  const data = await api.search();
  setRows(data);
} catch {
  setRows([]); // hides auth failures
}
```

**Correct:**

```javascript
try {
  const data = await api.search();
  setRows(data);
} catch (error) {
  Toast.Error(error.message || t('errors.searchFailed'));
  setRows([]);
  setErrorState(error);
}
```

Handle HTTP 401/403 explicitly - prompt re-auth or show unauthorized page.

Normalize API error shapes in one place:

- Envelope: `{ statusCode, message }` or `{ errors: [...] }`
- Problem Details: `title`, `detail`, `status`
- Transport: network / timeout messages via i18n keys

## Retry and idempotency

| Operation | Retry guidance |
|-----------|----------------|
| Idempotent GET | Optional exponential backoff (e.g. 2–3 attempts) on network/5xx |
| POST/PUT/PATCH/DELETE | Retry only when the API marks the operation safe to replay |
| 401/403/4xx business errors | Do **not** retry blindly |

Prefer axios/fetch interceptors or a small `withRetry` helper on the shared client - not ad-hoc loops in UI.

## API client structure

```
src/
  lib/
    services/
      api/
        client.js       # axios/fetch instance, interceptors, envelope unwrap, retry
        domain.js       # domain endpoints for this plugin
    constants/
      api.js            # routes, status enums
```

Configure base URL from `config/appsettings.json`:

```json
{
  "api": {
    "url": "",
    "key": ""
  }
}
```

Inject real values at deploy - never commit production keys.

## Endpoint coverage checklist

Before marking a feature complete, verify all controller routes needed by the UI are implemented in the client service layer.

Common gaps:

- List/search, getById, create/update/delete, export, exists/availability - implement only what the UI needs, but document gaps

## OpenAPI handoff

When backend exposes Swagger/OpenAPI, use `/api-integrate` in the backend repo to generate typed clients, then adapt unwrap logic for envelopes if the generator does not handle them.

## Testing API integration

- Mock API at the service layer in Cypress tests
- Integration tests against a test API environment - not production
- Verify auth header format in at least one test per authenticated endpoint
