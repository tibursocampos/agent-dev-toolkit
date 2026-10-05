# ESP-IDF validation and safety boundaries

## Report only exercised evidence

| Level | Demonstrates | Does not demonstrate by itself |
|---|---|---|
| Host-only | host-side deterministic tooling or parsing | target boot, peripherals, timing, radio, or recovery |
| Compile-only | C/C++ compatibility with the declared target/toolchain | flashing, startup, runtime memory, or HIL behavior |
| Device runtime | behavior observed on the named target and configuration | other revisions, production fleet behavior, or HIL |
| HIL | behavior observed with the named device, fixture, instruments, and scenario | untested setups and failure modes |

Keep static image size, section usage, heap, PSRAM, stacks, and runtime buffers as separate evidence. Do not infer dynamic memory or runtime headroom from a successful build or image size.

## Destructive-operation preflight

Before recommending or executing any flash, erase, or OTA operation, complete and record this preflight:

| Required evidence | Minimum question |
|---|---|
| Target | Which exact SoC, board/module, revision, and project target are selected? |
| Port/channel | Which verified serial port or OTA endpoint is the intended destination? |
| Partition table | Which partition table and bootloader layout are currently selected? |
| Backup | What approved backup exists for the data or firmware state that may be overwritten? |
| Recovery | How will the named target be recovered if the operation fails, and who approved that path? |

If any item is unknown, stale, or inconsistent with the project configuration, stop the operation-specific guidance. Ask for the missing evidence; do not guess a port, partition layout, backup, recovery command, or destructive flag. Treat eFuse changes and production provisioning as an additional review gate because they may be irreversible.

## Platform-qualified security decisions

Do not present a security control as enabled, supported, or safe to change until the actual SoC, ESP-IDF version, bootloader, configuration, threat/recovery context, and authoritative project evidence are identified. Apply the following conditions independently:

| Control | Required context before guidance |
|---|---|
| Secure boot / image signing | SoC and boot chain, signing mode and key boundary, bootloader configuration, update/recovery path, and threat model |
| Flash encryption | SoC and encryption mode, key/provisioning boundary, partition/data impact, recovery path, and production state |
| OTA / rollback / anti-rollback | OTA partition layout, image validation, version policy, failure/rollback behavior, connectivity trust boundary, and recovery procedure |
| eFuse / provisioning | Exact eFuse operation, irreversible effects, manufacturing/provisioning authority, backup/recovery limits, and explicit approval |

The presence of a generic ESP32 name, a compile result, or a preview project's configuration is not enough to satisfy these conditions. Never expose credentials, tokens, private keys, signing material, or device secrets while collecting evidence; use redacted placeholders and record only metadata needed to reproduce the review.

Never place credentials, tokens, private keys, signing material, or device secrets in source, `sdkconfig.defaults`, manifests, lockfiles, logs, or evidence. Use placeholders and describe the approved provisioning boundary instead.
