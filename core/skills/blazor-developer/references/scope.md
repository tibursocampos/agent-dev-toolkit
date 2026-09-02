# blazor-developer — scope

## When to escalate to SDD

Recommend `sdd-spec` -> `sdd-plan` -> `sdd-develop` if two or more apply: 3+ layers touched, new API contracts, cross-repo impact, 10+ files, or existing approved PLAN.

**Use `dotnet-developer`** for non-UI .NET (APIs, services, EF, messaging).

## DESIGN-BRIEF acceptance

If `docs/DESIGN-BRIEF.md` or `docs/design/DESIGN-BRIEF.md` exists, treat it as the acceptance source. Map sections to Razor components/layouts; do **not** reinterpret visual decisions. Implement **one session scope** from section 10 only.

For Hybrid targets, note platform-specific constraints in section 9 of the brief.

If the task is net-new UI without a brief, recommend `/impeccable shape` in a **new session** before implementing.

## Blazor host detection

Inspect `.csproj` and project layout:

| Signal | Host |
|--------|------|
| `Microsoft.AspNetCore.Components.WebAssembly` | **WASM** - client-side; API calls via HttpClient |
| `InteractiveServer` / Blazor Server SDK | **Server** - SignalR circuit; avoid long-blocking UI thread |
| `Microsoft.Maui` + BlazorWebView | **Hybrid** - native shell; note platform constraints in implementation |

Also detect via `_Imports.razor`, `App.razor`, or `Routes.razor`.
