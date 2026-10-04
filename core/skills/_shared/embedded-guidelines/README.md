# Embedded firmware guidelines

Shared guidance for firmware work when the target, runtime, framework, and validation boundary are still being established.

This pack is a cross-platform **WHAT** layer. It does not prescribe a language API, a framework API, a build system, a flashing procedure, or a host runtime. Load the platform-specific guidance only after the project identifies the applicable target and stack.

## Required context before making a platform-qualified claim

Record, or explicitly mark as missing:

- board or module name, exact revision, relevant variant, and target architecture;
- firmware runtime, framework/core family, version, and dependency source;
- project source for hardware facts: datasheet, board specification, measured result, or other named evidence;
- intended power, communication, storage, timing, and recovery constraints;
- validation boundary: host-only, compile-only, device runtime, or hardware-in-the-loop (HIL).

If a recommendation depends on absent context, ask for it before choosing a pin, peripheral, capability, limit, API, or platform operation.

## Pack map

- [Target and provenance](target-and-provenance.md): context, evidence, and state vocabulary.
- [Resources and communication](resources-and-communication.md): measurable budgets, payloads, queues, timeouts, and overload behavior.
- [Security and dependencies](security-and-dependencies.md): secrets, trust boundaries, dependency provenance, and platform-qualified security claims.
- [Validation and reporting](validation-and-reporting.md): host/compile/device/HIL boundaries and truthful status reporting.

## State vocabulary

Use the narrowest state supported by evidence. `confirmed`, `assumed`, `planned`, `implemented`, and `verified` are not interchangeable. A design document can support `planned`; it cannot by itself support `implemented` or `verified`.

## Boundary

The pack defines portable guardrails and questions. It must not duplicate stack-specific APIs, toolchain commands, board pin maps, or irreversible production settings. A platform-specific claim must name its target, version or revision when relevant, and source.
