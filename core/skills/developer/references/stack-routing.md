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
   | Native ESP-IDF signals such as `idf_component.yml`, a Component Manager lockfile, `idf_component_register`, ESP-IDF CMake structure, `sdkconfig`/`sdkconfig.defaults`, or project `idf.py` scripts | `esp-idf-developer`; preserve the observed CMake/`idf.py`, resolved dependencies, defaults, and local configuration |
   | Explicit Arduino Core/framework evidence with Arduino project metadata or dependency/version declaration | `arduino-developer`; do not treat Arduino compatibility or an ESP32 board name as native ESP-IDF evidence |
   | `platformio.ini` or equivalent with an environment explicitly declaring `framework = arduino` | `arduino-developer` (PlatformIO is conditional, not the default) |
   | Declared MicroPython runtime, firmware image workflow, or project runtime files with runtime/target/port evidence | `micropython-developer`; keep device APIs and deployment scoped to the identified MicroPython configuration |
   | `.ino`, `main.py`, or board-family name without framework/runtime and toolchain evidence | Request framework/core/runtime/version/toolchain evidence; do not infer Arduino, ESP-IDF, or MicroPython |
   | `package.json` (Node.js, no framework above) | `javascript-developer` |
   | `.csproj` / `.sln` without Blazor markers | `dotnet-developer` |
   | `pom.xml`, `build.gradle`, `build.gradle.kts`, or `settings.gradle` | `java-developer` |
   | CPython host tooling/tests, `.py`, `requirements.txt`, or `pyproject.toml` with host-runtime evidence | `python-developer`; do not add device APIs or flashing guidance |

   | C/C++ or Python host tooling/tests that exercise firmware without embedded project evidence | Route by the host language (`python-developer` for CPython); do not infer an embedded firmware framework |

   | Python source without runtime/target/port evidence where APIs or deployment could differ | Ask for runtime, target, and port evidence before choosing a device workflow; `.py` alone is not MicroPython evidence |

   Target and ESP-IDF version are separate evidence fields. A framework match does not establish either one: derive them from project declarations, configuration, build output, dependency metadata, lockfiles, or observed tool output; otherwise state the uncertainty and ask before version-sensitive guidance. Preserve `idf_component.yml`, lockfiles, `sdkconfig.defaults`, generated/local configuration, and existing resolved versions until a reviewed change is requested.

2. **Invoke the specialized skill (if match found)**:
   - Silently read the `SKILL.md` of the matched stack under `{{TOOLKIT_ROOT}}/skills/`:
     - `blip-plugin-developer`, `blazor-developer`, `electron-developer`, `vue-developer`, `react-native-developer`, `dotnet-developer`, `java-developer`, `react-developer`, `angular-developer`, `javascript-developer`, `python-developer`, `micropython-developer`, `arduino-developer`, or `esp-idf-developer`
   - Assume the identity and instructions of that skill immediately.
   - Do **not** ask the user for confirmation to switch skills.

3. **Fallback mode (if no match found)**:
   - If no major framework structure is detected (e.g., isolated `.html`, `.sh`, `.bat`, `.ps1` files), **do not delegate**.
   - Assume the task directly using standard, secure engineering practices as a Senior Developer.
   - Proceed to `references/fallback-execution.md`.
