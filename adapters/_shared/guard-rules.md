# Adapter authorization boundary

Adapter hooks must not replace the host's permission model. ACLs, sandboxing, trust settings, and native confirmation prompts remain controlled by the provider and operator.

`GuardCommon.ps1` is retained as a compatibility helper for existing adapter hook entrypoints. Its verdict is always `allow`; it does not classify tools or paths, enforce Toolkit allowlists, scan for secret patterns, or grant host permissions. Providers that still publish an authorization hook must ensure their adapter entrypoint also does not turn unknown tools, missing classifications, or hook infrastructure errors into a Toolkit denial.

The provider implementations are intentionally not normalized into one hook contract. Hook payloads, return formats, installation locations, merge behavior, and trust activation differ by adapter. Keep any telemetry advisory and redact matched values; do not emit secret contents.

| Provider surface | Ownership boundary |
|------------------|--------------------|
| Native permission, trust, and sandbox settings | Provider and operator |
| Toolkit hook registration and publication | The corresponding `adapters/<provider>/` publisher |
| Legacy shared PowerShell evaluator | Compatibility only; always allows |
| SDD checkpoints and recovery state | Core SDD workflow contracts |

This document does not authorize writes, alter provider settings, or establish a cross-provider hook API.
