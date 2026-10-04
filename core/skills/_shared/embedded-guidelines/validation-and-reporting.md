# Validation and reporting

## Keep validation levels distinct

Report the strongest level actually exercised, with the target and scenario:

| Level | Demonstrates | Does not demonstrate by itself |
|---|---|---|
| Host-only | host-side parsing, orchestration, or deterministic logic under the named host setup | target timing, electrical behavior, radio, boot, power, or recovery |
| Compile-only | source compatibility and compilation for the declared target/toolchain configuration | flashed behavior, startup, peripherals, memory headroom, or HIL behavior |
| Device runtime | behavior observed on the named board/revision and firmware configuration | untested revisions, production fleet behavior, or external-system/HIL scenarios |
| HIL | behavior across the named device, fixture, instruments, and scenario | claims outside that setup or unexercised failure modes |

Do not report a stronger level because a lower level passed. If hardware or the required fixture is unavailable, say so and retain the result as `host-only` or `compile-only`.

## Report evidence with state

Every result should include:

- target, revision, runtime/framework version, and relevant configuration;
- source or artifact under test;
- validation level and scenario;
- observed result, limitations, and any unavailable hardware or fixture;
- state transition, if any: `planned`, `implemented`, or `verified`.

“Build passed” is an observation about that build. It is not evidence that the firmware ran, that timing is acceptable, that a peripheral is wired correctly, or that recovery and security behavior work.

## Completion checklist

- [ ] Target and revision are identified or the missing context is recorded.
- [ ] Hardware and dependency facts have named provenance.
- [ ] Confirmed, assumed, planned, implemented, and verified states are not conflated.
- [ ] Memory, timing, payload, queue, timeout, and overload limits are bounded or explicitly pending measurement.
- [ ] Secrets are absent and dependency provenance is recorded.
- [ ] Host-only, compile-only, device runtime, and HIL evidence are reported separately.
- [ ] Platform-qualified claims name their applicability and do not rely on a neighboring stack.
