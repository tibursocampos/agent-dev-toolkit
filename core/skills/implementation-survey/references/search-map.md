# Search map

After stack discovery, load only the section whose heading is the selected stack. Leave the other sections unread.

Each section names where to look: entry points, tests, and dependency registration. A section is a search map. It is not a quality checklist.

## dotnet

### Entry points (dotnet)

`Program.cs`, `Startup`, HTTP endpoints, and hosted workers.

### Tests (dotnet)

Test projects and test classes next to the changed code (`xUnit`, `NUnit`, or `MSTest`, as the repo shows).

### Dependency registration (dotnet)

Service registration in `Program.cs` or `Startup`, and `PackageReference` entries in the project file.

## react-native

### Entry points (react-native)

App registration, `App` component, navigation, and Expo config when the project uses Expo.

### Tests (react-native)

Jest or Detox files the repo already contains, including `__tests__`.

### Dependency registration (react-native)

`package.json` dependencies and native module linking the project already declares.

## react

### Entry points (react)

`index` / `main`, root `App`, and route components.

### Tests (react)

Jest, Vitest, or React Testing Library files the repo already contains.

### Dependency registration (react)

`package.json` dependencies and provider composition at the root.

## angular

### Entry points (angular)

`main.ts`, `bootstrapApplication` or the root module, and route definitions.

### Tests (angular)

`*.spec.ts` files and the runner the repo already uses.

### Dependency registration (angular)

`providers` in the application config or root module, plus `package.json` and `angular.json`.

## vue

### Entry points (vue)

`main.ts` or `main.js`, root `App`, and the router.

### Tests (vue)

Vitest or Jest files the repo already contains.

### Dependency registration (vue)

`app.use` plugin registration and `package.json` dependencies.

## blazor

### Entry points (blazor)

`Program.cs`, `App.razor`, and the router component.

### Tests (blazor)

bUnit or other test projects the repo already contains.

### Dependency registration (blazor)

Service registration in `Program.cs` and package references in the project file.

## electron

### Entry points (electron)

Main-process entry, preload script, and renderer entry.

### Tests (electron)

Test files the repo already runs for the main process or the renderer.

### Dependency registration (electron)

`package.json` dependencies and `BrowserWindow` / IPC wiring the project already shows.

## javascript

### Entry points (javascript)

`package.json` `main` or `bin`, and the server or script file that starts the process.

### Tests (javascript)

Node test runner, Jest, or other test files the repo already contains.

### Dependency registration (javascript)

`package.json` dependencies and explicit `require` / `import` of collaborators at the entry.

## java

### Entry points (java)

The main class, a framework application class, and HTTP or message handlers.

### Tests (java)

JUnit classes under the test source set the repo already uses.

### Dependency registration (java)

`pom.xml` or Gradle dependency declarations, and framework configuration types that register collaborators.

## python

### Entry points (python)

The module, application object, or CLI the process starts from (FastAPI, Flask, or a script, as the repo shows).

### Tests (python)

pytest (or another runner) files the repo already contains.

### Dependency registration (python)

`pyproject.toml`, `requirements*.txt`, or the framework's dependency container when the project shows one.

## micropython

### Entry points (micropython)

Device entry the project declares (`main.py`, `boot.py`, or the port entry the repo shows), with runtime, target, or port evidence already present.

### Tests (micropython)

Host or device tests the repo already contains for that firmware workflow.

### Dependency registration (micropython)

Frozen modules, manifests, or package lists the firmware project already declares.

## esp-idf

### Entry points (esp-idf)

`app_main` and the component `CMakeLists.txt` files that register sources.

### Tests (esp-idf)

Test applications or Unity targets the repo already declares.

### Dependency registration (esp-idf)

`idf_component.yml`, Component Manager lockfiles, and `REQUIRES` / `idf_component_register` in CMake.

## arduino

### Entry points (arduino)

Sketch `setup` / `loop` and libraries the sketch already includes, when Arduino Core or `framework = arduino` evidence is present.

### Tests (arduino)

Test sketches or host tests the repo already contains.

### Dependency registration (arduino)

`library.properties`, platform metadata, and library includes the sketch already uses.

## blip-plugin

### Entry points (blip-plugin)

Plugin scaffold entry, exported commands, and the extension surface the project already ships.

### Tests (blip-plugin)

Test files the plugin repo already contains.

### Dependency registration (blip-plugin)

The plugin `package.json` dependencies and extension registration the scaffold already shows.
