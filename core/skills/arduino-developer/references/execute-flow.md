# arduino-developer — execute flow

## Orientation checklist

Before changing a sketch or library, inspect:

1. board/module, architecture, variant, and revision;
2. Arduino Core family and exact version;
3. library and dependency declarations, including provenance;
4. Arduino IDE/CLI or configured PlatformIO metadata and version;
5. source layout (`.ino`, library `src/`, examples, and project scripts);
6. available validation boundary and hardware/fixture availability.

Record unknowns explicitly. A board label without a core declaration is insufficient to choose Arduino APIs or ESP-IDF behavior.

## Tool selection

Follow the project’s declared configuration. Preserve existing commands and versions. PlatformIO is conditional on a relevant `platformio.ini` or equivalent project declaration; it is not a universal fallback. Do not introduce `idf.py`, CMake, MicroPython tooling, or CPython tooling into an Arduino flow without matching project evidence.

## Validation report

Use a separate result for each level:

| Result | Minimum evidence |
|--------|------------------|
| Host-only | named host and inspected deterministic behavior |
| Compile-only | declared board/core/toolchain and compiler result |
| Upload | named board/revision, port, tool, and observed transfer |
| Device runtime | named board/revision, firmware configuration, scenario, and observed behavior |
| HIL | named device, fixture/instruments, and scenario |

State what was not exercised. Never promote compile-only into upload, runtime, or HIL.

## Target-specific boundary

For ESP32/ESP8266, identify Arduino Core and version from project evidence before using Arduino compatibility or APIs. Native ESP-IDF remains a separate framework even when Arduino Core is implemented over ESP-IDF internals.
