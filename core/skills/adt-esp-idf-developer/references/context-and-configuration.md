# ESP-IDF context and configuration

## Identify before recommending

Capture the smallest context that can change the answer:

| Field | Acceptable evidence | If absent |
|---|---|---|
| Framework | ESP-IDF CMake structure, `idf.py`, `idf_component.yml`, `idf_component_register`, or explicit project declaration | Do not route to this skill; ask which framework is authoritative |
| Target | project target declaration, `sdkconfig`, build output, board/module record, or operator evidence | Ask; do not infer from an ESP32 family name |
| ESP-IDF version | project record, tool output, dependency metadata, lockfile, or explicit operator evidence | Mark version-sensitive guidance uncertain and ask for confirmation |
| Toolchain | project scripts, CMake/toolchain files, observed `idf.py`, or installation metadata | Inspect before prescribing a command or installation |
| Configuration | `sdkconfig.defaults`, generated `sdkconfig`, component configuration, and project overrides | Preserve existing state and identify the missing source |

Record each material item as `confirmed`, `assumed`, `planned`, `implemented`, or `verified`. A preview project can confirm the version for that project only; it cannot set a toolkit-wide default.

## Framework boundary

Native ESP-IDF remains distinct from Arduino Core, even where Arduino is used as an ESP-IDF component. MicroPython firmware and CPython host tooling remain outside this skill. A board or SoC label alone is ambiguous and must not select a framework.

## Configuration preservation

- Treat `sdkconfig.defaults` as versioned project input when present.
- Treat generated or local `sdkconfig` as environment/project state that requires comparison before replacement.
- Inspect `idf_component.yml` and the Component Manager lockfile before changing dependencies.
- Preserve resolved versions and local configuration unless a reviewed change is explicitly requested.
- Do not copy credentials or sensitive local values into examples, defaults, manifests, lockfiles, or logs.
