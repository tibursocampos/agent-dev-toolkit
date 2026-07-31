# Blazor components

Razor component structure, parameters, binding, and lifecycle for WASM, Server, and Hybrid. Render-mode selection lives in `blazor-render-modes.md`. Cross-cutting a11y/tests: hub `frontend-guidelines/` — do not duplicate those paragraphs here.

---

## MUST

- One component per `.razor` file; PascalCase type name matches the file name.
- Declare public inputs with `[Parameter]`; use `EventCallback` / `EventCallback<T>` for parent notifications — do not invent ad-hoc Action props when EventCallback is the project norm.
- Prefer `@bind` / `@bind-Value` for two-way binding; use `@bind-Value:after` (.NET 8+) when a post-bind side effect is required.
- Implement lifecycle correctly: one-time work in `OnInitialized(Async)`; react to parameter changes in `OnParametersSet(Async)`; DOM / JS work in `OnAfterRender(Async)` with a `firstRender` guard when needed.
- Dispose subscriptions, timers, and cancellation tokens via `IDisposable` / `IAsyncDisposable` when the component owns them.
- Keep Razor markup thin: extract growing logic to partial class code-behind, scoped services, or existing project patterns — match what neighbors already do.
- Use CSS isolation (`Component.razor.css`) when the project already scopes styles that way.
- Keep identifiers, comments, and source in English; user-facing copy follows repo i18n.

```razor
@code {
    [Parameter] public string Title { get; set; } = string.Empty;
    [Parameter] public EventCallback OnSave { get; set; }

    private async Task HandleSaveAsync() => await OnSave.InvokeAsync();
}
```

### Lifecycle quick map

| Method | Use |
|--------|-----|
| `OnInitialized` / `Async` | One-time setup, first load |
| `OnParametersSet` / `Async` | React to parameter / cascading changes |
| `OnAfterRender` / `Async` | DOM-dependent or JS interop (`firstRender`) |
| `IDisposable` / `IAsyncDisposable` | Unsubscribe, cancel, release |

---

## MUST NOT

- Block the UI thread with long synchronous work (especially Interactive Server circuits).
- Call JS or touch the DOM before the first render completes without a `firstRender` / readiness check.
- Mutate `[Parameter]` properties as local state — copy into private fields when local mutation is needed.
- Fire-and-forget `async void` event handlers; use `async Task` and surface errors per project logging.
- Introduce a second component folder layout when `Components/`, `Pages/`, or feature folders already exist.
- Duplicate hub frontend a11y paragraphs inside component files; load `frontend-guidelines/` instead.

---

## Prefer when matching repo

| Signal | Prefer |
|--------|--------|
| Code-behind `.razor.cs` already used | Keep logic out of the markup file |
| `@typeparam` generics in shared UI | Follow existing generic component patterns |
| Design system / shared chrome | Place under `Components/Shared/` or the project’s design-system folder |
| Immediate input updates | `@bind:event="oninput"` only when neighbors need it |
| Explicit change handlers | `@onchange` when bind semantics are unclear |
| Hybrid (MAUI + BlazorWebView) | Platform APIs via MAUI services bridged through DI |

### Server vs WASM habits

- **Server:** update UI from background work with `InvokeAsync`; avoid long `Task.Delay` on the circuit thread.
- **WASM:** configure `HttpClient` `BaseAddress` as the template already does; lazy-load assemblies/routes only when the project already supports it.

### Parameter and callback habits

| Habit | Detail |
|-------|--------|
| Required params | Use `[EditorRequired]` / project equivalent when the template already does |
| Child content | `[Parameter] public RenderFragment? ChildContent` matching siblings |
| Cascading | Prefer named cascading values when unnamed collisions already bit the repo |
| Error UI | Reuse existing `ErrorBoundary` / layout error fragments — do not invent a one-off |

### Before merging a component change

1. Confirm host + render mode (see `blazor-render-modes.md`).
2. Grep a sibling component in the same feature and match structure.
3. Ensure dispose paths exist for any subscription added in this PR.
4. Add or update a bUnit test for the behavior change (`blazor-testing.md`).

---

## References

- [ASP.NET Core Blazor components](https://learn.microsoft.com/en-us/aspnet/core/blazor/components/)
- [Blazor component lifecycle](https://learn.microsoft.com/en-us/aspnet/core/blazor/components/lifecycle)
- [Cascading values and parameters](https://learn.microsoft.com/en-us/aspnet/core/blazor/components/cascading-values-and-parameters)
- [ASP.NET Core Blazor event handling](https://learn.microsoft.com/en-us/aspnet/core/blazor/components/event-handling)
