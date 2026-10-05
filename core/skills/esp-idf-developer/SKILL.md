---
name: esp-idf-developer
description: >-
  Implement or diagnose native ESP-IDF C/C++ firmware using the project's declared
  target, ESP-IDF version, CMake configuration, idf.py workflow, and Component Manager metadata.
---

## STOP - Read before ANY tool call

1. Read `{{GUARDRAILS_PATH}}`
2. Read `_shared/sdd-artifacts/SESSION.md`; load session-state for `$Cwd`
3. If the relevant gate is not approved: **STOP** - ask user **(pt-BR)** - do **NOT** Write/Shell
4. SDD/develop skills: after **ONE** step/task, **STOP** session - handoff only
5. This skill body is **English**; user-facing prompts may be **(pt-BR)**

---

# Skill: esp-idf-developer

## Trigger

Invoke for native ESP-IDF applications and components written in C or C++ when project evidence identifies ESP-IDF. A board name such as ESP32, ESP32-S3, or ESP32-C3 is not framework evidence by itself.

## Outcome

Provide configuration-aware implementation or diagnosis for the project's ESP-IDF target and version. Preserve the project's CMake and `idf.py` workflow, Component Manager resolution, and configuration files. Report unknown target or version context explicitly and keep compile-only evidence separate from device evidence.

## Lazy-load

| When | Path |
|------|------|
| Target, version, and framework evidence | `references/context-and-configuration.md` |
| CMake, `idf.py`, and Component Manager workflow | `references/build-and-dependencies.md` |
| Validation boundaries and safe reporting | `references/validation-and-safety.md` |
| Forbidden assumptions and framework boundaries | `references/must-not.md` |
| Shared embedded WHAT layer | `{{TOOLKIT_ROOT}}/skills/_shared/embedded-guidelines/README.md`, `target-and-provenance.md`, `security-and-dependencies.md`, `validation-and-reporting.md` |

Do not preload unrelated framework packs or the whole shared memory bank. Load only the reference needed for the current claim.

**Never by default:** Do not preload unrelated framework packs, prescribe a universal ESP-IDF version or toolchain, or claim device/runtime evidence from a host-only or compile-only result.

## Process

### 0. Establish project evidence

Before recommending an API, command, target-specific option, or security feature, inspect the project and record the evidence state for:

- target SoC, board/module, variant, and revision;
- ESP-IDF version and provenance;
- CMake project structure and authoritative build entry point;
- `idf.py` availability and the observed installation/environment;
- `idf_component.yml`, Component Manager lockfile, and dependency sources;
- `sdkconfig.defaults`, generated local configuration, and any project-specific overrides;
- validation boundary: host-only, compile-only, device runtime, or HIL.

If target or version evidence is missing, ask for it or state the uncertainty before using version-sensitive guidance. Never infer ESP-IDF from an ESP32 family name alone.

### 1. Preserve the native workflow

Treat the project's CMake files and `idf.py` commands as the build source of truth. Inspect existing components and registration before changing them. Use Component Manager metadata and its resolved lockfile as dependency evidence; do not silently replace resolved versions or introduce a new package manager.

Distinguish versioned defaults such as `sdkconfig.defaults` from generated or local `sdkconfig` state. Compare configuration before changing it and preserve local state unless the operator explicitly requests a reviewed change.

### 2. Condition host setup on observation

Give PowerShell, ESP-IDF environment, and managed Python instructions only when the project or host inspection shows that installation and shell are applicable. Preserve the observed ESP-IDF installation and Python environment rather than prescribing a universal path, version, or activation command. A version mentioned by a preview project is project-specific evidence, never a global default for this skill or toolkit.

### 3. Implement and report narrowly

Use the project's C/C++ layout and existing component boundaries. Label results separately as host-only, compile-only, device runtime, or HIL, and include the target, version, configuration, and observed command or scenario. A successful cross-build does not prove flashing, boot, peripheral behavior, timing, memory headroom, or HIL behavior.

For flash, erase, OTA, boot, secure-boot, encryption, signing, rollback, or provisioning guidance, require the target, version, bootloader/configuration, and recovery context first. Keep credentials, tokens, private keys, and device secrets out of source, configuration, logs, and evidence.

Before any flash, erase, or OTA operation, run the preflight in `references/validation-and-safety.md`: exact target, verified port or OTA channel, partition table, approved backup, and recovery evidence are all required. If one is missing, stop operation-specific guidance. Treat secure boot, flash encryption, signing, rollback, OTA, eFuse, and provisioning as separate decisions qualified by the actual SoC/version/configuration and threat/recovery context.

## Handoff

For a larger approved change, use `sdd-develop` with the canonical PLAN path. For a commit, use `commit`; for review, use `code-review`.
