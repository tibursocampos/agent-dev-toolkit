## Stack routing

When the request explicitly identifies a PLAN, route before stack detection. A story PLAN (`features/<feature>/{USnn|TSnn}/PLAN/PLAN_*.md`) goes to direct `adt-sdd-develop` unless the current handoff explicitly selects O3 context. A Delivery PLAN at the feature root or in `plans/<unit>/PLAN.md` goes to `adt-delivery-implement`. The owner resolves the manifest-selected path, validates approval and extracts the step. The router neither edits the PLAN nor forwards the request as unplanned work when the selected PLAN is missing. When its caller is already executing a step, a stack skill receives only the scoped code/tests work and returns evidence to that caller. Ordinary stack detection below applies to ad-hoc work.

1. **Inspect the workspace** - identify stack in this order (frameworks before generic Node):

   | Signal | Route to |
   |--------|----------|
   | User asks for **new** Blip plugin scaffold (no existing `blip-ds` project) | `adt-blip-plugin-developer` |
   | `package.json` with `blip-ds` and `iframe-message-proxy` (existing Blip plugin) | `adt-react-developer` (loads `blip-guidelines/`) |
   | `.csproj` with `Microsoft.AspNetCore.Components`, or `_Imports.razor` / `App.razor` | `adt-blazor-developer` |
   | `package.json` with `electron`, `electron-builder`, or `electron-vite` | `adt-electron-developer` |
   | `package.json` with `vue` (and not React/Angular) | `adt-vue-developer` |
   | `package.json` with `react-native` or `expo` | `adt-react-native-developer` |
   | `package.json` with `react` | `adt-react-developer` |
   | `package.json` with `@angular/core` or `angular` | `adt-angular-developer` |
   | Native ESP-IDF signals such as `idf_component.yml`, a Component Manager lockfile, `idf_component_register`, ESP-IDF CMake structure, `sdkconfig`/`sdkconfig.defaults`, or project `idf.py` scripts | `adt-esp-idf-developer`; preserve the observed CMake/`idf.py`, resolved dependencies, defaults, and local configuration |
   | Explicit Arduino Core/framework evidence with Arduino project metadata or dependency/version declaration | `adt-arduino-developer`; do not treat Arduino compatibility or an ESP32 board name as native ESP-IDF evidence |
   | `platformio.ini` or equivalent with an environment explicitly declaring `framework = arduino` | `adt-arduino-developer` (PlatformIO is conditional, not the default) |
   | Declared MicroPython runtime, firmware image workflow, or project runtime files with runtime/target/port evidence | `adt-micropython-developer`; keep device APIs and deployment scoped to the identified MicroPython configuration |
   | `.ino`, `main.py`, or board-family name without framework/runtime and toolchain evidence | Request framework/core/runtime/version/toolchain evidence; do not infer Arduino, ESP-IDF, or MicroPython |
   | `package.json` (Node.js, no framework above) | `adt-javascript-developer` |
   | `.csproj` / `.sln` without Blazor markers | `adt-dotnet-developer` |
   | `pom.xml`, `build.gradle`, `build.gradle.kts`, or `settings.gradle` | `adt-java-developer` |
   | CPython host tooling/tests, `.py`, `requirements.txt`, or `pyproject.toml` with host-runtime evidence | `adt-python-developer`; do not add device APIs or flashing guidance |
   | C/C++ or Python host tooling/tests that exercise firmware without embedded project evidence | Route by the host language (`adt-python-developer` for CPython); do not infer an embedded firmware framework |
   | Python source without runtime/target/port evidence where APIs or deployment could differ | Ask for runtime, target, and port evidence before choosing a device workflow; `.py` alone is not MicroPython evidence |

   Target and ESP-IDF version are separate evidence fields. A framework match does not establish either one: derive them from project declarations, configuration, build output, dependency metadata, lockfiles, or observed tool output; otherwise state the uncertainty and ask before version-sensitive guidance. Preserve `idf_component.yml`, lockfiles, `sdkconfig.defaults`, generated/local configuration, and existing resolved versions until a reviewed change is requested.

2. **Invoke the specialized skill (if match found)**:
   - Silently read the `SKILL.md` of the matched stack under `{{TOOLKIT_ROOT}}/skills/`:
     - `adt-blip-plugin-developer`, `adt-blazor-developer`, `adt-electron-developer`, `adt-vue-developer`, `adt-react-native-developer`, `adt-dotnet-developer`, `adt-java-developer`, `adt-react-developer`, `adt-angular-developer`, `adt-javascript-developer`, `adt-python-developer`, `adt-micropython-developer`, `adt-arduino-developer`, or `adt-esp-idf-developer`
   - Assume the identity and instructions of that skill immediately.
   - Do **not** ask the user for confirmation to switch skills.

3. **Fallback mode (if no match found)**:
   - If no major framework structure is detected (e.g., isolated `.html`, `.sh`, `.bat`, `.ps1` files), use the scoped delegation rules in `references/fallback-execution.md`.
   - Assume the task directly using standard, secure engineering practices as a Senior Developer.
   - Proceed to `references/fallback-execution.md`.
