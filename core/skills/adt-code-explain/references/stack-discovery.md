# Stack discovery

Read the Signal table in `core/skills/_shared/agents/ROUTING.md`. Do not edit that file. Walk the rows in the order already published there.

A primary-stack row selects a stack only when its signal is present. The stack ids, in that published order, are `dotnet`, `react-native`, `react`, `angular`, `vue`, `blazor`, `electron`, `javascript`, `java`, `python`, `micropython`, `esp-idf`, `arduino`, and `blip-plugin`.

Exactly one matching primary-stack row selects that stack. Stop the walk there. Then load only that stack's section from `references/search-map.md`.

Two or more matching primary-stack rows are mixed evidence. Ask one question. Do not select a stack.

No matching primary-stack row is absence of evidence. Ask one question. Do not select a stack.

The rows below never select a stack. They are not an extra stack id. `Mixed / unclear` is one of those rows, not a fifteenth stack.

| Published signal | Result |
|------------------|--------|
| `.cs` / `.csproj` / EF | `dotnet` |
| React Native / Expo | `react-native` |
| React / TSX | `react` |
| Angular | `angular` |
| Vue | `vue` |
| Blazor | `blazor` |
| Electron | `electron` |
| Node / plain JS | `javascript` |
| Java / `pom.xml` / Gradle | `java` |
| CPython host applications, tools, or tests (including host code that communicates with firmware) | `python` |
| Declared MicroPython runtime/firmware workflow with runtime, target, or port evidence | `micropython` |
| Native ESP-IDF evidence (`idf_component.yml`, Component Manager lockfile, `idf_component_register`, ESP-IDF CMake structure, `sdkconfig`/`sdkconfig.defaults`, or project `idf.py` scripts) | `esp-idf` |
| Explicit Arduino Core/framework evidence, Arduino metadata, or configured `framework = arduino` | `arduino` |
| `.ino`, `main.py`, or board-family name without framework/runtime/toolchain evidence | Ask one question. Do not infer a stack from the board name. |
| Python or `.py` without runtime/target evidence when APIs or deployment could differ | Ask one question. Do not infer `micropython` from the extension. |
| Mixed / unclear | Ask one question. This row is not a stack. |
| UI shape / audit first | Not a primary stack. Do not select a stack from this row. |
| Blip plugin scaffold | `blip-plugin` |

An ESP32-family name alone does not select `esp-idf`, `arduino`, or `micropython`. CPython host code stays on `python` when that row is the only match, including host code that talks to firmware.
