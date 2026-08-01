# Blazor Components

Razor component patterns for WASM, Server, and Hybrid. Match project structure (`Components/`, `Pages/`, layouts).

## Component basics

```razor
@code {
    [Parameter] public string Title { get; set; } = string.Empty;
    [Parameter] public EventCallback OnSave { get; set; }

    private async Task HandleSaveAsync()
    {
        await OnSave.InvokeAsync();
    }
}
```

- One component per file; PascalCase names matching file name.
- Use `@typeparam` for generic components when the project already does.

## Data binding

- `@bind` for two-way binding; `@bind:event="oninput"` for immediate updates when needed.
- `@bind-Value` / `@bind-Value:after` (.NET 8+) for post-bind callbacks.
- Prefer explicit `@onchange` when bind semantics are unclear.

## Lifecycle

| Method | Use |
|--------|-----|
| `OnInitialized` / `OnInitializedAsync` | One-time setup |
| `OnParametersSet` / `OnParametersSetAsync` | React to parameter changes |
| `OnAfterRender` / `OnAfterRenderAsync` | DOM-dependent logic (`firstRender` check) |
| `IDisposable` / `IAsyncDisposable` | Unsubscribe, cancel tokens |

## Render modes (.NET 8+)

- **Server**: interactive server components - mind circuit latency.
- **WebAssembly**: client execution - bundle size matters.
- **Auto**: follow project default; do not mix modes without reason.

## Code organization

- Extract logic to scoped services or partial class code-behind when components grow.
- Shared UI in `Components/Shared/` or design system folder per project.
- CSS isolation via `Component.razor.css` when the project uses scoped styles.

## Server-specific

- Avoid long `Task.Delay` or blocking calls on the UI thread.
- Use `InvokeAsync` when updating UI from background threads.

## WASM-specific

- HttpClient for API calls; configure BaseAddress in `Program.cs` pattern already in project.
- Lazy-load assemblies/routes when the template supports it.
