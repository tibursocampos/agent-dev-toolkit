# Resources and communication

## Make budgets explicit

Treat resources as budgets to measure on the target, not as properties inferred from source size or a successful compile. Record the unit, measurement point, operating condition, and margin for:

- program/image storage and persistent data;
- static memory, heap, stack, external memory, and runtime buffers;
- CPU time, scheduling latency, interrupt work, and power or thermal limits;
- I/O bandwidth, storage wear, radio airtime, and retry capacity;
- startup, shutdown, recovery, and degraded-mode behavior.

Separate static footprint from runtime headroom. A compile-only result does not establish heap, stack, buffer, timing, power, thermal, or radio margins.

## Bound messages and queues

For each asynchronous producer/consumer path, specify before implementation:

| Boundary | Required limit or policy |
|---|---|
| Payload | maximum encoded size, accepted shape, and rejection behavior |
| Queue | maximum item count, item storage cost, and ownership/lifetime |
| Rate | expected and peak arrival rate, burst size, and service rate |
| Time | enqueue, processing, acknowledgement, and expiry limits |
| Overload | bounded drop, backpressure, coalescing, or fail-closed behavior |
| Recovery | retry cap, cancellation, drain policy, and observability |

Never describe a queue as “unlimited” on a constrained target. If the project has no measured budget, mark the value `assumed` and block a claim of safe capacity until it is measured or otherwise confirmed.

Timeouts and overflow handling must preserve memory bounds. A retry policy must also have a bound; repeated retries are not a substitute for backpressure or a failure mode.

## Hardware and timing boundaries

Keep electrical and timing claims qualified by the target, revision, operating condition, and evidence. Software guidance does not certify voltage, current, signal integrity, radio behavior, thermal safety, or regulatory compliance. Refer those questions to the applicable hardware source and validation setup.

## Review questions

- Which budget is measured, which is assumed, and what margin remains?
- Can a burst, retry, or slow consumer make memory grow without a fixed bound?
- Does the failure path avoid blocking indefinitely or silently discarding critical data?
- Is the observed limit valid for the selected target and runtime, rather than a neighboring platform?
