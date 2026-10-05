# Agent routing -> stack skills

Orchestrators and specialists **do not** reimplement stack work. Point implementation to existing developer skills.

| Signal | Route |
|--------|-------|
| `.cs` / `.csproj` / EF | `/dotnet-developer` |
| React Native / Expo | `/react-native-developer` |
| React / TSX | `/react-developer` |
| Angular | `/angular-developer` |
| Vue | `/vue-developer` |
| Blazor | `/blazor-developer` |
| Electron | `/electron-developer` |
| Node / plain JS | `/javascript-developer` |
| Java / `pom.xml` / Gradle | `/java-developer` |
| CPython host applications, tools, or tests (including host code that communicates with firmware) | `/python-developer` |
| Declared MicroPython runtime/firmware workflow with runtime, target, or port evidence | `/micropython-developer` |
| Native ESP-IDF evidence (`idf_component.yml`, Component Manager lockfile, `idf_component_register`, ESP-IDF CMake structure, `sdkconfig`/`sdkconfig.defaults`, or project `idf.py` scripts) | `/esp-idf-developer` |
| Explicit Arduino Core/framework evidence, Arduino metadata, or configured `framework = arduino` | `/arduino-developer` |
| `.ino`, `main.py`, or board-family name without framework/runtime/toolchain evidence | `/developer` (request framework/core/runtime/version/toolchain evidence; do not infer by board name) |
| Python or `.py` without runtime/target evidence when APIs or deployment could differ | `/developer` (ask for runtime, target, and port evidence; do not infer MicroPython from the extension) |
| Mixed / unclear | `/developer` (router) |
| UI shape / audit first | `/impeccable` -> DESIGN-BRIEF -> stack skill |
| Blip plugin scaffold | `/blip-plugin-developer` |

The ESP-IDF route is evidence-based and must remain distinct from Arduino Core and MicroPython. An ESP32-family name alone never selects a framework. Derive the target and ESP-IDF version separately from project/configuration/build evidence, and preserve `idf_component.yml`, resolved lockfiles, `sdkconfig.defaults`, generated `sdkconfig`, and other local configuration until a reviewed change is requested. CPython host code and tests remain on `/python-developer`, even when they interact with embedded firmware.

**Subagent-first (after route):** `*-developer` skills follow `_shared/developer-common/subagent-first.md` and `_shared/agents/SPAWN.md` (capability `subagents`; trivial **in-parent**; medium/complex ≤2 children or **fallback**).

## Orchestrator boundaries

| Skill | May spawn | Must not |
|-------|-----------|----------|
| `orchestrate-analyze` | Roster specialists via Task | Call `*-developer` to write app code |
| `orchestrate-deliver` | Contracts of `sdd-spec` / `sdd-plan` per story | Implement code |
| `orchestrate-develop` | One subagent per PLAN step using `sdd-develop` contract | Parent writes app code; multi-step in one child |

**Task model:** see `SUBAGENT-MODEL.md` — omit `model` by default; premium only after rare hard-task gate + user **sim**.

**Caveman receipts:** when `caveman_mode` is ON, specialists return the schema in `RECEIPT.md` (ultra structured findings). Parent inherits prefs `caveman_level` but **never** compresses gates or artifact drafts. Prefer level `ultra` only for long multi-specialist O1 sessions. Load `_shared/caveman/CAVEMAN.md` only if mode ON.

**Memory-bank (Orchestrated Delivery Step 0):** after gate, pass resolved `bank_root` (`$Cwd/memory-bank/` or `<classic.path>/memory-bank/` per `STORAGE.md`) as **read-only** Prior context to specialists / O2 draft Tasks / O3 develop children (selective files). Do not place bank under `features/`. Classic SDD / manual `sdd-*` do not require the gate. Optional narrative compact: `_shared/caveman/COMPACT.md` (user **sim**).

## Review

After O3 or manual develop: `/code-review` (name `- single` or `- multi-angle`, or let the skill ask - no silent default).
