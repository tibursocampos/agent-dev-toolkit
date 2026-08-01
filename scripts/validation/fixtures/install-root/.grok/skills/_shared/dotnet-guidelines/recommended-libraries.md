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

## Polly

**Category**: Resilience & Fault Handling  
**NuGet**: `Polly`

### Why we recommend it
Polly is a comprehensive resilience and transient-fault-handling library. It enables developers to easily express policies such as Retry, Circuit Breaker, Timeout, Bulkhead Isolation, and Fallback in a fluent and thread-safe manner.

### Key Features
- Retry with backoff strategies (exponential, jitter, etc.)
- Circuit Breaker to protect downstream services
- Timeout handling
- Fallback execution on failure
- Bulkhead isolation for resource management
- Policy wrapping and composition

### Resources
- [Official Polly GitHub](https://github.com/App-vNext/Polly)
- [Polly Documentation](https://github.com/App-vNext/Polly/wiki)
