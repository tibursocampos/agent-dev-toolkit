# Blazor state and forms

Local vs shared state, cascading values, and `EditForm` validation. Auth/routing gates: `blazor-routing-auth.md`. Detect Fluxor, MediatR, or plain services from the project before introducing a store.

---

## MUST

- Keep **ephemeral UI state** as private fields in `@code` / code-behind unless multiple distant components need it.
- Share cross-component state via **scoped/singleton services** already registered in `Program.cs` / `Startup`, or via cascading values when the project already cascades that concern (theme, layout, culture).
- Prefer a **service** over deep cascading trees when many unrelated descendants need the same mutable data.
- Use `EditForm` with `DataAnnotationsValidator` (or the project’s FluentValidation integration) for forms that submit domain models.
- Show field errors with `ValidationMessage` / `ValidationSummary` consistent with existing forms.
- Guard submit with an `isSubmitting` (or equivalent) flag to prevent double posts.
- Separate **UI state** (modals, drafts, toggles) from **server/async state** (HTTP results, circuit-backed stores) — do not mirror query results into redundant private fields “for convenience.”

```razor
<EditForm Model="@model" OnValidSubmit="HandleSubmitAsync">
    <DataAnnotationsValidator />
    <ValidationSummary />
    <InputText @bind-Value="model.Name" />
    <button type="submit" disabled="@isSubmitting">Save</button>
</EditForm>
```

```razor
<CascadingValue Value="theme" Name="Theme">
    @ChildContent
</CascadingValue>
```

---

## MUST NOT

- Introduce Fluxor, Redux.NET, or a second MediatR pipeline when the repo uses plain DI services (or the inverse).
- Cascade large mutable graphs that every leaf rewrites — prefer a dedicated state service.
- Skip validation on the client and assume the API alone is enough when the screen already uses `EditForm` patterns.
- Leave submit buttons enabled during in-flight saves when sibling forms disable them.
- Put HTTP, persistence, or domain rules inside presentational leaf components when controllers/services already own that layer.

---

## Prefer when matching repo

| Signal | Prefer |
|--------|--------|
| Fluxor present | Actions / reducers / effects in existing feature folders |
| MediatR present | Thin Razor; `IMediator` commands/queries in Application layer |
| FluentValidation | Match existing `AbstractValidator` registration; do not add a parallel DataAnnotations-only path on the same form family |
| Cascading auth / theme | Extend existing `CascadingValue` / `CascadingAuthenticationState` |
| Hybrid (MAUI) | Platform state via MAUI services; bridge into Blazor through DI |

### State placement cheatsheet

| Kind | Where |
|------|--------|
| Ephemeral UI | Private fields on the component |
| Shared in one layout tree | Cascading value or layout-scoped service |
| App-wide session / cache | Existing scoped/singleton store |
| Remote entities | HttpClient / application services (`blazor-js-interop.md` only for JS needs) |

### Forms checklist (inline)

1. Model type matches existing DTO/view-model naming.
2. Validators match the form family already in the feature.
3. Disable submit while saving; reset flag in `finally`.
4. On success, navigate or raise `EventCallback` the way siblings do.

### Input component map

| Need | Prefer |
|------|--------|
| Text | `InputText` / `InputTextArea` |
| Numbers | `InputNumber` |
| Bool | `InputCheckbox` |
| Dates | `InputDate` (or project date picker) |
| Select | `InputSelect` / design-system select already used |

Do not drop to raw `<input>` + manual wiring when the feature already uses `Input*` components.

### Anti-patterns

```csharp
// Wrong — mirror Http result into redundant state forever
_orders = await client.GetOrdersAsync();
// later still using a second copy updated only sometimes

// Right — single source: field/service/query result used for render
_orders = await client.GetOrdersAsync();
```

Keep one authoritative copy of server data; derive UI flags in render when cheap.

---

## References

- [ASP.NET Core Blazor forms and validation](https://learn.microsoft.com/en-us/aspnet/core/blazor/forms/)
- [Cascading values and parameters](https://learn.microsoft.com/en-us/aspnet/core/blazor/components/cascading-values-and-parameters)
- [Blazor components overview](https://learn.microsoft.com/en-us/aspnet/core/blazor/components/)
- [Input components](https://learn.microsoft.com/en-us/aspnet/core/blazor/forms/input-components)
