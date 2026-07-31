# Recommended Libraries for .NET

This page documents a curated list of recommended .NET libraries. These libraries are selected based on community adoption, internal usage, reliability, and maintainability.

## Internal C# Starter Kit

**Category**: Internal SDKs & Starters  
**NuGet**: Multiple packages under `Internal.Starter.Common.*` (internal feed)

### Why we recommend it
The Internal C# Starter Kit provides a pre-configured starting point for building .NET applications following the company's standards. It includes libraries for structured logging, tracing, secrets management, environment config, and more, reducing boilerplate and ensuring consistency across projects.

### Included Modules
- `Logs`: Structured logging with Serilog + enrichers
- `Traces`: OpenTelemetry tracing setup
- `Secrets`: Secure access to secrets via Hashicorp Vault
- `Metrics`: Exporting metrics (Prometheus, etc.)
- `Authentication`: AuthN/AuthZ helpers

> To use the internal packages, make sure to install the appropriate credential provider for the package registry.

---

## HTTP resilience (`Microsoft.Extensions.Http.Resilience`)

**Category**: Resilience & Fault Handling  
**NuGet**: `Microsoft.Extensions.Http.Resilience` (built on Polly v8)

### Why we recommend it
For `HttpClient` calls resolved through `IHttpClientFactory`, use Microsoft’s HTTP resilience handlers. They wrap Polly v8 strategies with HTTP-aware defaults, telemetry, and configuration binding.

### Prefer

```csharp
services.AddHttpClient("orders")
    .AddStandardResilienceHandler();
```

Customize with `AddResilienceHandler` when standard defaults are not enough. For non-HTTP operations (database, message publish, arbitrary delegates), use Polly v8 `ResiliencePipeline` via `Microsoft.Extensions.Resilience` / `AddResiliencePipeline` as needed.

### Resources
- [HTTP resilience in .NET](https://learn.microsoft.com/en-us/dotnet/core/resilience/http-resilience)
- [Resilience in .NET](https://learn.microsoft.com/en-us/dotnet/core/resilience/)
- [Polly](https://www.thepollyproject.org/)

---

## Package versioning and supply-chain hygiene (Prefer)

| Practice | When |
|----------|------|
| **Central Package Management** (`Directory.Packages.props`) | Prefer for greenfield solutions and when matching an existing repo that already uses CPM |
| **`dotnet list package --vulnerable`** | Prefer on PR/CI to surface known vulnerable dependencies |
| **`dotnet nuget why <package>`** | Prefer when diagnosing why a transitive package entered the graph |
| **Target framework** | Match the repository; for greenfield without a house standard, prefer the org’s current **LTS** TFM |

### Commercial dispatcher / mapper libraries

**MediatR** (v13+) and **AutoMapper** (v15+) require a commercial license for many commercial teams. This toolkit standardizes on **Command / Handler / FluentValidation / Response** structure without requiring MediatR. Prefer when matching repo: keep the existing dispatcher; for greenfield, use an OSS-licensed pin, an approved licensed version, or an internal pipeline - do not introduce a paid package without explicit approval.
