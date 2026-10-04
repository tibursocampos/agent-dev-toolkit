## Stack routing

1. **Inspect the workspace** - identify stack in this order (frameworks before generic Node):

   | Signal | Route to |
   |--------|----------|
   | User asks for **new** Blip plugin scaffold (no existing `blip-ds` project) | `blip-plugin-developer` |
   | `package.json` with `blip-ds` and `iframe-message-proxy` (existing Blip plugin) | `react-developer` (loads `blip-guidelines/`) |
   | `.csproj` with `Microsoft.AspNetCore.Components`, or `_Imports.razor` / `App.razor` | `blazor-developer` |
   | `package.json` with `electron`, `electron-builder`, or `electron-vite` | `electron-developer` |
   | `package.json` with `vue` (and not React/Angular) | `vue-developer` |
   | `package.json` with `react-native` or `expo` | `react-native-developer` |
   | `package.json` with `react` | `react-developer` |
   | `package.json` with `@angular/core` or `angular` | `angular-developer` |
   | Native ESP-IDF signals such as `idf_component.yml`, `idf_component_register`, ESP-IDF CMake structure, `sdkconfig`, or project `idf.py` scripts | ESP-IDF workflow; do not route by ESP32/ESP8266 board name |
   | Explicit Arduino Core/framework evidence with Arduino project metadata or dependency/version declaration | `arduino-developer` |
   | `platformio.ini` or equivalent with an environment explicitly declaring `framework = arduino` | `arduino-developer` (PlatformIO is conditional, not the default) |
   | `.ino` or board-family name without Arduino Core/framework and toolchain evidence | Request framework/core/version/toolchain evidence; do not infer Arduino or ESP-IDF |
   | `package.json` (Node.js, no framework above) | `javascript-developer` |
   | `.csproj` / `.sln` without Blazor markers | `dotnet-developer` |
   | `pom.xml`, `build.gradle`, `build.gradle.kts`, or `settings.gradle` | `java-developer` |
   | `.py`, `requirements.txt`, `pyproject.toml` | `python-developer` |

2. **Invoke the specialized skill (if match found)**:
   - Silently read the `SKILL.md` of the matched stack under `{{TOOLKIT_ROOT}}/skills/`:
     - `blip-plugin-developer`, `blazor-developer`, `electron-developer`, `vue-developer`, `react-native-developer`, `dotnet-developer`, `java-developer`, `react-developer`, `angular-developer`, `javascript-developer`, `python-developer`, or `arduino-developer`
   - Assume the identity and instructions of that skill immediately.
   - Do **not** ask the user for confirmation to switch skills.

3. **Fallback mode (if no match found)**:
   - If no major framework structure is detected (e.g., isolated `.html`, `.sh`, `.bat`, `.ps1` files), **do not delegate**.
   - Assume the task directly using standard, secure engineering practices as a Senior Developer.
   - Proceed to `references/fallback-execution.md`.
