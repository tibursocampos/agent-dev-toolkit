# Blazor performance

Measure-first rendering, list virtualization, and host-aware costs. Render-mode choice often dominates micro-optimizations — see `blazor-render-modes.md`.

---

## MUST

- **Measure before optimizing** (Browser DevTools, `dotnet-counters`, Server circuit logs, or project APM). Do not sprinkle `ShouldRender` overrides or virtualization “just in case.”
- Prefer narrowing **interactive render boundaries** over making entire layouts interactive when the template supports islands/static SSR.
- Use `Virtualize` for large interactive lists when the project already depends on it or list length is demonstrably costly.
- Keep `[Parameter]` changes cheap: avoid passing new collection/delegate instances every parent render when children are heavy and the repo already memoizes equivalents.
- On Interactive Server, avoid chatty event handlers (`oninput` on large trees) when `onchange` / debounced patterns exist nearby.
- On WebAssembly, respect existing lazy assembly loading and trim/AOT settings in publish profiles — do not disable trim to “fix” a size issue without root-cause.
- Dispose event subscriptions and JS module refs so idle circuits/tabs do not leak (`blazor-components.md`, `blazor-js-interop.md`).

```razor
<Virtualize Items="@orders" Context="order">
    <OrderRow Model="order" />
</Virtualize>
```

```csharp
protected override bool ShouldRender() => _shouldRender;
// Only when profiling shows wasted renders AND siblings already use this pattern
```

---

## MUST NOT

- Override `ShouldRender` globally or copy-paste it into every component without evidence.
- Load heavy JS chart/editor libraries on every route when only one page needs them.
- Poll APIs in tight loops on Server circuits; prefer existing push/notification patterns or backoff.
- Allocate large byte arrays or images in component fields without disposal / size limits.
- Force Interactive Auto on media-heavy pages without checking dual download cost.

---

## Prefer when matching repo

| Signal | Prefer |
|--------|--------|
| `Virtualize` already used | Match `ItemsProvider` vs in-memory `Items` style |
| Fluxor / central store | Select minimal slices; avoid whole-store cascading |
| CSS isolation + large DOM | Reduce DOM depth before micro-tuning diffing |
| WASM lazy routes | Extend existing `AdditionalAssemblies` / lazy route story |
| Server streaming / SSR | Keep static shells static; hydrate interactive islands only |

### Hot-path cheatsheet

| Symptom | First check |
|---------|-------------|
| Slow click handling (Server) | Circuit thread blocked? too many `oninput`? |
| Large WASM download | Lazy assemblies, trim, duplicate static assets |
| List jank | Virtualize; simplify row components |
| Re-render storms | Parameter identity; cascading value churn |
| JS chart lag | Init once after render; dispose on navigate |

### Before a perf PR

1. Capture a baseline (trace or timing note in the PR).
2. Change one bottleneck at a time.
3. Re-measure the same path.
4. Keep diffs scoped — no drive-by render-mode rewrites.

### Rendering budget habits

| Cost | Mitigation |
|------|------------|
| Wide cascading values updating often | Narrow the cascade or use a service + `StateHasChanged` at owners |
| Heavy child under frequent parent render | Split parameters; avoid inline lambdas if siblings already cache handlers |
| Large tables | `Virtualize` or paginate like existing screens |
| Image-heavy WASM | Compress assets; lazy-load routes/assemblies already configured |

### Server circuit notes

- Prefer fewer, coarser UI updates over per-keystroke full-tree refreshes on large forms.
- Cancel `CancellationTokenSource` work when navigating away so abandoned circuits do not keep running queries.
- Do not hold large datasets in scoped services longer than the page needs without an existing cache policy.

---

## References

- [ASP.NET Core Blazor performance best practices](https://learn.microsoft.com/en-us/aspnet/core/blazor/performance)
- [Virtualization](https://learn.microsoft.com/en-us/aspnet/core/blazor/components/virtualization)
- [Render modes](https://learn.microsoft.com/en-us/aspnet/core/blazor/components/render-modes)
- [ASP.NET Core Blazor hosting model performance](https://learn.microsoft.com/en-us/aspnet/core/blazor/hosting-models)
