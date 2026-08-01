# Blazor JavaScript interop

`IJSRuntime` / `IJSObjectReference` patterns, module loading, and disposal. Prefer Blazor-native APIs before reaching for JS. Testing mocks: `blazor-testing.md`.

---

## MUST

- Inject `IJSRuntime` (or a project abstraction over it) — do not call JS through static helpers invented for one screen.
- Prefer **ES module** imports (`InvokeAsync<IJSObjectReference>("import", "./js/file.js")` or `IJSRuntime` module helpers the template uses) over scattering global functions on `window`.
- Call browser/DOM APIs only from `OnAfterRenderAsync` (or after an explicit ready signal), guarding with `firstRender` when initialization must run once.
- Dispose `IJSObjectReference` / `IJSStreamReference` with `IAsyncDisposable` when the component owns them.
- Keep JS files under the project’s existing `wwwroot` / static assets layout; match naming and bundling already in the repo.
- Handle `JSDisconnectedException` / circuit loss on Interactive Server when invoking during teardown (match existing try/catch patterns).
- Pass only serializable, minimal payloads across the boundary — no giant object graphs.

```csharp
protected override async Task OnAfterRenderAsync(bool firstRender)
{
    if (!firstRender) return;
    _module = await JS.InvokeAsync<IJSObjectReference>("import", "./js/chart.js");
    await _module.InvokeVoidAsync("init", ElementId);
}

public async ValueTask DisposeAsync()
{
    if (_module is not null)
        await _module.DisposeAsync();
}
```

```javascript
// wwwroot/js/chart.js
export function init(elementId) { /* ... */ }
```

---

## MUST NOT

- Use `[JSInvokable]` static entry points that mutate global static state when instance callbacks / `DotNetObjectReference` already exist in the feature.
- Forget to dispose `DotNetObjectReference` created for JS → .NET callbacks.
- Load large third-party scripts on every page when the feature is route-local — scope to the component/module that needs them.
- Bypass Blazor forms, navigation, or auth with raw JS when a C# API already exists.
- Embed secrets, tokens, or privileged URLs in JS bundles for WASM clients.

---

## Prefer when matching repo

| Signal | Prefer |
|--------|--------|
| Existing `IJSRuntime` extension wrappers | Reuse; do not add a parallel helper |
| `JSImport` / `[JSImport]` (.NET 7+ WASM) | Use when the project already adopted JS.[Import] source generation |
| Design-system scripts | Follow the package’s documented init/dispose |
| Hybrid MAUI | Prefer MAUI handlers / native APIs over web JS when the capability is platform-native |
| CSP present | External modules must satisfy the app’s Content-Security-Policy |

### Interop direction

| Direction | API |
|-----------|-----|
| .NET → JS | `IJSRuntime.InvokeAsync` / module `InvokeAsync` |
| JS → .NET | `DotNetObjectReference` + `[JSInvokable]` on instance methods |
| Streams | `IJSStreamReference` / `DotNetStreamReference` per existing file upload patterns |

### Server vs WASM

- **Server:** JS runs in the browser; .NET on server — expect latency; never assume sync DOM reads in C#.
- **WASM:** same-process feel but still async; trim/AOT may affect linked JS footprints — follow publish settings already in CI.

### DotNetObjectReference sketch

```csharp
_dotNetRef = DotNetObjectReference.Create(this);
await _module.InvokeVoidAsync("subscribe", _dotNetRef);

[JSInvokable]
public Task OnJsEventAsync(string payload) => InvokeAsync(StateHasChanged);

public async ValueTask DisposeAsync()
{
    _dotNetRef?.Dispose();
    if (_module is not null)
        await _module.DisposeAsync();
}
```

Always dispose the `DotNetObjectReference` when the component tears down.

### When not to use JS

| Need | Prefer Blazor / .NET |
|------|----------------------|
| Navigation | `NavigationManager` |
| Focus / forms | Built-in components + validation |
| HTTP | `HttpClient` |
| Timers | `System.Threading.Timer` / periodic patterns already in-repo |

---

## References

- [Call JavaScript from .NET (Blazor)](https://learn.microsoft.com/en-us/aspnet/core/blazor/javascript-interoperability/call-javascript-from-dotnet)
- [Call .NET from JavaScript (Blazor)](https://learn.microsoft.com/en-us/aspnet/core/blazor/javascript-interoperability/call-dotnet-from-javascript)
- [JavaScript isolation in JavaScript modules](https://learn.microsoft.com/en-us/aspnet/core/blazor/javascript-interoperability/javascript-isolation-modules)
- [JSDisconnectedException](https://learn.microsoft.com/en-us/dotnet/api/microsoft.jspinterop.jsdisconnectedexception)
