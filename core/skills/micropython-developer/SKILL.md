---
name: micropython-developer
description: >-
  Implement or diagnose MicroPython device firmware for identified ESP32 or
  ESP8266 targets, with runtime and port evidence kept separate from CPython
  host tooling and tests.
---

## STOP - Read before ANY tool call

1. Read `{{GUARDRAILS_PATH}}`
2. Read `_shared/sdd-artifacts/SESSION.md`; load session-state for `$Cwd`
3. If the relevant gate is not approved: **STOP** - ask user **(pt-BR)** - do **NOT** Write/Shell
4. SDD/develop skills: after **ONE** step/task, **STOP** session - handoff only
5. This skill body is **English**; user-facing prompts may be **(pt-BR)**

### Step -1 - Gate check (report in chat before continuing)

```
Gate check:
[ ] guardrails.mdc read
[ ] SESSION.md read; session-state loaded
[ ] PIPELINE.md read (SDD skills only)
[ ] User confirmed current action (sim)
-> If any unchecked: STOP
```

---

# Skill: micropython-developer

## Trigger

Invoke for Python code that runs as MicroPython firmware on an identified ESP32
or ESP8266 device. A `.py` extension, an ESP32-family name, or a board label
alone is not enough to select this skill.

## Outcome

Provide a bounded, evidence-aware firmware workflow for the selected
MicroPython runtime and target. Keep device execution, device deployment, and
host-side tooling or tests distinct. Treat ESP32 and ESP8266 as the initial
first-class target families without assuming that their ports, firmware builds,
boards, or available modules share one uniform API or deployment capability.

## Lazy-load

| When | Path |
|------|------|
| Shared embedded context and evidence | `{{TOOLKIT_ROOT}}/skills/_shared/embedded-guidelines/README.md`, `target-and-provenance.md`, `validation-and-reporting.md` |
| Resource and constrained-runtime questions | `{{TOOLKIT_ROOT}}/skills/_shared/embedded-guidelines/resources-and-communication.md` |
| Security or dependency questions | `{{TOOLKIT_ROOT}}/skills/_shared/embedded-guidelines/security-and-dependencies.md` |
| ESP32 reference | `https://docs.micropython.org/en/latest/esp32/quickref.html` |
| ESP8266 reference | `https://docs.micropython.org/en/latest/esp8266/quickref.html` |
| MicroPython library availability | `https://docs.micropython.org/en/latest/library/index.html` |
| Invocation context | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/INVOCATION-CONTEXTS.md` (`IC-DIRECT-ORCHESTRATED`) |
| Contract provenance | `{{TOOLKIT_ROOT}}/skills/_shared/sdd-artifacts/CONTRACT-PROVENANCE.md` (`CP-AGREED-VS-INVENTED`) |

Do not preload unrelated framework packs or the whole memory bank. Load
platform-specific references only after the runtime, port, firmware, board,
and validation boundary are identified.

**Never by default:** do not preload port references, firmware-specific API
guides, deployment procedures, security material, or the memory bank before
the runtime, port, firmware, board, and validation boundary are known.

## Process

### 0. Establish and qualify the device context

Before making a target-qualified recommendation, create a context record with
all of these fields:

| Field | Required evidence | Boundary when missing |
|------|-------------------|-----------------------|
| Board/module | exact model, variant, revision, and architecture from board documentation or operator evidence | do not choose pins, peripherals, limits, or deployment behavior |
| Port | `esp32` or `esp8266`, including any port-specific variant named by the firmware | do not generalize between ESP32 and ESP8266 |
| Firmware | MicroPython version, build/source provenance, and relevant configuration | do not treat `latest` documentation as proof for the installed build |
| API/module source | port quick reference, version-matched library reference, or project dependency metadata | report the capability as `unknown` or `pending confirmation` |
| Hardware source | datasheet, board specification, measured result, or named project evidence | do not infer electrical, memory, radio, or storage facts from the family name |
| Validation boundary | `host-only`, `compile-only`, `device runtime`, or `HIL` | do not report a stronger result than the exercised boundary |

For every recommendation, explicitly separate three workstreams:

1. **Host tooling/tests**: commands and tests executed by CPython on the host;
2. **Deployment**: an operation that changes the device, only when an
   authoritative procedure for the exact board/firmware is identified;
3. **Device execution**: REPL or runtime behavior observed on the named board,
   revision, and firmware.

If a missing field could change the API, module, resource, or deployment answer,
ask for it before recommending a target-dependent operation. Do not infer it
from the file extension, board family, or a nearby ESP32/ESP8266 example.

Use the narrowest state supported by evidence: `confirmed`, `assumed`,
`planned`, `implemented`, or `verified`. A reference page or project plan can
support a planned recommendation; it does not prove that a particular firmware
build exposes or verifies that capability.

### 0.1 Select authoritative references before using an API or module

Select references by the recorded port and firmware version. The initial
reference map is:

| Claim | Required reference |
|------|--------------------|
| ESP32 port API/peripherals | [MicroPython ESP32 quick reference](https://docs.micropython.org/en/latest/esp32/quickref.html), matched to the selected documentation/release when available |
| ESP8266 port API/peripherals | [MicroPython ESP8266 quick reference](https://docs.micropython.org/en/latest/esp8266/quickref.html), matched to the selected documentation/release when available |
| Cross-port module availability | [MicroPython library reference](https://docs.micropython.org/en/latest/library/index.html), checked against the selected firmware build |
| Board pins, electrical limits, and revision differences | the exact board/module documentation or datasheet; a port quick reference is not a board pinout |
| Deployment or recovery | the exact firmware release/project procedure for the named board; do not substitute a generic flashing or OTA recipe |

Record the URL or document identifier and the version/date used. The `latest`
pages are navigation aids, not evidence that an installed older build has the
same API. If the source covers a different port, board revision, or build,
label the guidance `pending confirmation` and do not present it as supported.

### 0.2 Qualify REPL, deployment, and resource guidance

- **REPL:** identify the board/revision and firmware build before suggesting
  introspection or runtime checks. Use only commands documented for that exact
  runtime; a successful host import or a REPL transcript from another build is
  not device evidence.
- **Deployment:** state whether the action is host preparation, a device-changing
  deployment action, or post-deployment device validation. Do not invent flash,
  erase, recovery, or OTA steps. If the authoritative procedure is not known,
  report deployment as `pending confirmation` and request the target-qualified
  procedure.
- **Hardware and resources:** tie pins, peripherals, storage, memory, timing,
  power, and radio claims to the exact board/revision and firmware source or a
  measurement. A successful compile or a file-size estimate does not establish
  runtime headroom, timing, electrical safety, or radio behavior.
- **Validation:** report host-only, compile-only, device-runtime, and HIL
  results separately, including the target and scenario. Never promote a
  host-only or compile-only result to flashed behavior.

### 1. Keep the runtime boundary explicit

MicroPython firmware is device-runtime work. CPython applications, host tools,
host tests, and general Python web work remain with `python-developer`, even
when they communicate with a board. Do not mix host test results with device
runtime evidence.

When runtime or target information is ambiguous, request the smallest missing
context before recommending runtime-dependent syntax, modules, APIs, or
deployment operations.

### 2. Scope the initial target

This skill treats ESP32 and ESP8266 MicroPython firmware as its initial
first-class coverage. Other MicroPython ports, Linux-based single-board
computers, native ESP-IDF, Arduino C/C++, and CPython-on-SBC applications are
outside that first-class boundary. They may be mentioned only to explain a
handoff or a boundary; they do not inherit this skill's assumptions.

For any target-qualified claim, name the applicable port, firmware, board, and
reference. If the source does not establish support for the selected
configuration, report the capability as unknown or pending confirmation.

### 3. Report narrowly

State what was inspected or exercised and the validation level. A host-only or
compile-only result does not establish flashed behavior, startup, peripherals,
memory headroom, timing, radio behavior, recovery, or hardware safety. Do not
claim a deployment method or device capability merely because another ESP32 or
ESP8266 configuration supports it.

### 3.1 Security and Arduino Cloud boundaries

- Treat TLS, certificate or hostname validation, OTA, secure storage, secure
  boot, signed updates, rollback, and key-management behavior as `unknown` or
  `pending confirmation` until the exact port, firmware build, board, and
  authoritative reference establish support. Encrypted transport alone is not
  evidence of peer authentication.
- Keep credentials, tokens, private keys, and provisioning values outside
  source, examples, REPL transcripts, logs, and evidence. Describe only the
  approved provisioning boundary with non-sensitive placeholders.
- Arduino Cloud guidance is limited to firmware-side communication or
  protocol integration on an identified ESP32 or ESP8266 port, firmware, and
  board. Verify the exact MicroPython compatibility and required modules
  before recommending it; dashboard, service, account, fleet, and other
  administration are out of scope.
- Do not claim upload, OTA, device runtime, HIL, or hardware evidence unless
  that exact target and validation boundary were actually exercised.

## Must not

- Infer MicroPython from `.py`, `main.py`, an ESP32/ESP8266 family name, or a board label alone.
- Treat CPython host code or tests as MicroPython device code, or route host work away from `python-developer`.
- Present ESP32 and ESP8266 ports, firmware builds, boards, or modules as a uniform API surface.
- Treat another MicroPython port, Linux SBC, native ESP-IDF project, or Arduino C/C++ project as first-class coverage here.
- Invent flashing, OTA, TLS, storage, memory, or other deployment/security capabilities without target-qualified evidence.
- Put credentials, tokens, private keys, or device secrets in examples, logs, or evidence.
- Claim device runtime or HIL validation from host inspection or compilation alone.
- Ignore `IC-DIRECT-ORCHESTRATED` or promote an `invented` gap to an agreed requirement; follow the cited invocation-context and contract-provenance rules.
- Auto-commit or auto-push.

## Handoff

For port-, firmware-, REPL-, deployment-, resource-, or security-specific work,
continue only after loading the applicable shared and target references. For
CPython host tooling or tests, hand off to `python-developer`. For other
frameworks or ports, hand off to the matching workflow with the target evidence
recorded.
