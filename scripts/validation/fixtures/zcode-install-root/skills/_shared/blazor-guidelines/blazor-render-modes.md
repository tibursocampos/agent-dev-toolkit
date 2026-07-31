# Blazor render modes (.NET 8+)

Interactive render modes, static SSR boundaries, and host-aware defaults. Component structure: `blazor-components.md`. Perf micro-habits: `blazor-performance.md`.

---

## MUST

- Detect the host from `.csproj` / `Program.cs` / `Routes.razor` before changing interactivity: **Static SSR**, **Interactive Server**, **Interactive WebAssembly**, **Interactive Auto**, or **Hybrid** (MAUI BlazorWebView).
- Set render modes explicitly at the boundary the project already uses (`@rendermode`, `AddInteractive*`, page-level attributes) — do not silently change global defaults in a small fix.
- Treat **Interactive Server** as a SignalR circuit: avoid long blocking work; prefer async APIs; use `InvokeAsync` when updating UI from background threads.
- Treat **Interactive WebAssembly** as a download + client runtime: keep payloads lean; respect existing lazy-loading of assemblies/routes.
- Use **Auto** only when the project already standardized on it; document which components stay Server-only vs WASM-capable when mixing.
- Keep static (non-interactive) pages static unless the acceptance criteria require interactivity.
- For .NET 8+ unified apps, respect `HeadOutlet`, `Routes`, and existing `MapRazorComponents` / render-mode endpoint configuration.

### Mode cheatsheet

| Mode | Runs where | Mind |
|------|------------|------|
| Static SSR | Server, no circuit | No event handlers / no client state |
| Interactive Server | Server + SignalR | Latency, circuit lifetime, thread affinity |
| Interactive WebAssembly | Browser | Bundle size, AOT/trim, HttpClient |
| Interactive Auto | Server first, then WASM | Dual asset + mode switch behavior |
| Hybrid | Native WebView | Platform APIs via MAUI DI |

```razor
@* Match project attribute style *@
@rendermode InteractiveServer
```

```csharp
// Program.cs — only extend the registration style already present
builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents();
```

---

## MUST NOT

- Mix Server and WASM interactivity on the same component tree without an existing project pattern for boundaries/prerender.
- Enable global interactivity “to make a button work” when a single interactive island would suffice and the template uses islands.
- Assume pre-.NET 8 `_Host.cshtml` / `blazor.server.js` patterns on a .NET 8+ `App.razor` + `Routes.razor` host (or the reverse).
- Block the Server circuit with sync I/O or `Thread.Sleep`.
- Ship Auto mode components that depend on Server-only services without a WASM-safe abstraction the repo already provides.

---

## Prefer when matching repo

| Signal | Prefer |
|--------|--------|
| .NET 8+ Blazor Web App template | Page/component `@rendermode`; keep `Program.cs` registration aligned |
| Legacy Blazor Server / WASM hosted | Keep `_Host` / `Blazor.webassembly.js` patterns; do not force render-mode attributes |
| Prerender on | Preserve prerender settings; fix hydration issues rather than disabling casually |
| Shared UI library | Interactive components declare mode at consumption site when the library is mode-agnostic |
| Hybrid MAUI | Do not apply web render-mode attributes that the WebView host ignores; use host docs |

### Choosing interactivity (small change)

1. Read how sibling pages declare mode.
2. Add the narrowest interactive boundary that satisfies the UX.
3. Avoid changing `Program.cs` render-mode registration unless required for a new host capability.
4. Smoke: hard refresh, navigate away/back, and (Server) reconnect after brief offline if circuits matter.

### Prerender and serialization

- When prerender is on, avoid reading browser-only state in `OnInitialized` — defer to `OnAfterRenderAsync` or enhanced-nav patterns the host already uses.
- Do not pass non-serializable services across static→interactive boundaries without the project’s existing cascading/service approach.
- If a component errors only after interactivity starts, compare static SSR markup vs interactive path before flipping modes off.

### Detection snippets

| Look for | Likely host |
|----------|-------------|
| `AddInteractiveServerComponents` | Server interactivity |
| `AddInteractiveWebAssemblyComponents` | WASM interactivity |
| `AddInteractiveAutoRenderMode` / Auto attributes | Auto |
| `BlazorWebView` / MAUI | Hybrid |
| No interactive registration + static pages | Static SSR-first |

---

## References

- [ASP.NET Core Blazor render modes](https://learn.microsoft.com/en-us/aspnet/core/blazor/components/render-modes)
- [Blazor fundamentals — hosting models](https://learn.microsoft.com/en-us/aspnet/core/blazor/hosting-models)
- [What’s new in ASP.NET Core Blazor](https://learn.microsoft.com/en-us/aspnet/core/release-notes/aspnetcore-8.0#blazor)
- [Prerender and integrate ASP.NET Core Razor components](https://learn.microsoft.com/en-us/aspnet/core/blazor/components/prerender)
