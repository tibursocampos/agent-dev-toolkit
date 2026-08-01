# Blazor routing and authentication

`Router` / `NavLink`, authorize views, and policy-aligned route guards. Shared auth state patterns overlap with `blazor-state.md` — keep cascading auth here when it is route-scoped.

---

## MUST

- Register and discover routes the way the host already does (`@page`, `Routes.razor`, `Router` `AppAssembly` / additional assemblies).
- Use `NavLink` (or the design-system equivalent) for in-app navigation so active CSS classes stay consistent.
- Protect interactive pages with `[Authorize]`, `AuthorizeRouteView`, and/or `AuthorizeView` matching the template — do not invent a parallel guard only for one screen.
- Rely on `CascadingAuthenticationState` / `AuthenticationStateProvider` already wired in the project; extend providers rather than forking a second auth cascade.
- Apply **authorization policies** already defined in `Program.cs` / `Startup` (`[Authorize(Policy = ...)]`) instead of hard-coded role string checks scattered in markup.
- Keep anonymous vs authenticated layouts consistent with existing `AuthorizeRouteView` `NotAuthorized` / `Authorizing` fragments.
- For WASM or BFF-style auth, follow the project’s token/cookie/OIDC flow — do not add a second MSAL/OIDC client beside the configured one.

```razor
@attribute [Authorize(Policy = "OrdersRead")]
@page "/orders"
```

```razor
<AuthorizeView Policy="OrdersWrite">
    <Authorized>
        <EditOrderForm />
    </Authorized>
    <NotAuthorized>
        <p>Forbidden</p>
    </NotAuthorized>
</AuthorizeView>
```

---

## MUST NOT

- Duplicate authorization only in the UI (hide buttons) without route/API enforcement the backend already expects.
- Navigate with raw `window.location` / JS when `NavigationManager` is available.
- Store access tokens in `localStorage` when the project standardized on cookies/BFF — or the reverse.
- Mix `[AllowAnonymous]` broadly on layouts that were meant to be authenticated end-to-end.
- Hard-code return URLs or authority endpoints; use configuration and existing auth options.

---

## Prefer when matching repo

| Signal | Prefer |
|--------|--------|
| .NET 8 `Routes.razor` + `AuthorizeRouteView` | Extend that composition |
| Legacy `App.razor` `Router` | Keep `Found` / `NotFound` templates aligned |
| Policy-based auth | Named policies over ad-hoc `Roles =` when policies already exist |
| Role-based template | Stick to roles; do not introduce policies in a one-line fix |
| Deep links / query | `NavigationManager.GetUriWithQueryParameter` or existing helpers |
| Hybrid MAUI | Use secure storage / platform auth bridges the app already registered |

### Navigation habits

- Prefer `NavigationManager.NavigateTo` with `forceLoad: true` only when a full document reload is required (auth cookie refresh patterns already in repo).
- Match trailing-slash and base-href behavior of the host (`<base href>` in `wwwroot/index.html` / layout).
- For unauthorized redirects, reuse the existing `Authentication` / `Account` page paths.

### Checklist before adding a protected page

1. Confirm `@page` route and menu entry.
2. Apply the same `[Authorize]` / policy as sibling features.
3. Verify `NotAuthorized` UX still works (redirect vs message).
4. Smoke: anonymous → challenge; authorized → render; forbidden policy → NotAuthorized.

### Route parameter habits

- Match `{id:int}` / `{slug}` constraints already used in the feature.
- Validate route values in `OnParametersSetAsync` when IDs drive HTTP calls; show the project’s not-found UI when missing.
- Prefer `SupplyParameterFromQuery` / existing query helpers over parsing `NavigationManager.Uri` by hand.

### Auth provider extension

When adding claims or roles:

1. Locate the existing `AuthenticationStateProvider` (or remote auth state provider).
2. Extend it — do not register a second provider beside it.
3. Update policy registration in `Program.cs` in the same change set when a new policy name is introduced.
4. Cover `AuthorizeView` not-authorized markup with a bUnit auth helper if the suite has one.

---

## References

- [ASP.NET Core Blazor routing and navigation](https://learn.microsoft.com/en-us/aspnet/core/blazor/fundamentals/routing)
- [ASP.NET Core Blazor authentication and authorization](https://learn.microsoft.com/en-us/aspnet/core/blazor/security/)
- [Secure ASP.NET Core Blazor WebAssembly](https://learn.microsoft.com/en-us/aspnet/core/blazor/security/webassembly/)
- [NavLink component](https://learn.microsoft.com/en-us/dotnet/api/microsoft.aspnetcore.components.routing.navlink)
