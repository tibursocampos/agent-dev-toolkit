# arduino-developer — scope

## In scope

- Arduino sketches (`.ino`) and Arduino libraries.
- Arduino Core projects for Arduino-family boards and ESP32/ESP8266 only when the project identifies that core.
- Board/core/version/toolchain orientation and configuration-aware implementation or diagnosis.
- Arduino IDE/CLI or configured PlatformIO workflows, without prescribing one universally.
- Firmware-side Arduino Cloud integration.

## Out of scope

- Native ESP-IDF applications and their `idf.py`/CMake workflow; use the ESP-IDF skill.
- MicroPython firmware; use the MicroPython skill.
- General CPython applications, host tools, and host tests; use `python-developer`.
- Arduino Cloud dashboards or service administration.
- Hardware design, electrical certification, or first-class support for families outside the declared initial scope.

## Escalate or block when

The board/module revision, runtime, Arduino Core and version, declared toolchain, dependency provenance, or validation boundary is missing and the requested recommendation depends on it. Ask for the smallest missing context instead of guessing.
