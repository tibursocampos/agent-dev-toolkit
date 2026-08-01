# Blazor State and Forms

State management and forms in Blazor. Detect Fluxor, MediatR, or custom stores from the project.

## Component state

- Local UI state: private fields in `@code`.
- Shared state: scoped/singleton services registered in `Program.cs` / `Startup`.
- Cascading parameters for theme, auth, or layout context - avoid deep cascades when a service is clearer.

```razor
<CascadingValue Value="theme" Name="Theme">
    @ChildContent
</CascadingValue>
```

## EditForm and validation

```razor
<EditForm Model="@model" OnValidSubmit="HandleSubmit">
    <DataAnnotationsValidator />
    <ValidationSummary />
    <InputText @bind-Value="model.Name" />
    <button type="submit">Save</button>
</EditForm>
```

- Use `DataAnnotations` or FluentValidation per project convention.
- Display field errors with `ValidationMessage For="..."`.
- Disable submit while `isSubmitting` to prevent double posts.

## Fluxor (when present)

- Actions, reducers, effects - follow existing feature folders.
- Do not introduce Fluxor if the project uses plain services.

## MediatR (when present)

- Commands/queries from UI via injected `IMediator`.
- Keep Razor components thin; handlers in Application layer.

## Authentication state

- `AuthorizeView`, `CascadingAuthenticationState` per project template.
- Do not duplicate auth checks - use policy attributes on routes when available.

## Hybrid (MAUI + Blazor)

- Platform APIs via MAUI services; bridge to Blazor through DI.
- Test on target platforms when layout or native chrome is involved.
