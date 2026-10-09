# Search map

After stack discovery, load only the section whose heading is the selected stack. Leave the other sections unread.

Each section names where to look: entry points, tests, and dependency registration. A section is a search map. It is not a quality checklist.

## dotnet

### Entry points

`Program.cs`, `Startup`, HTTP endpoints, and hosted workers.

### Tests

Test projects and test classes next to the changed code (`xUnit`, `NUnit`, or `MSTest`, as the repo shows).

### Dependency registration

Service registration in `Program.cs` or `Startup`, and `PackageReference` entries in the project file.

## react-native

### Entry points

App registration, `App` component, navigation, and Expo config when the project uses Expo.

### Tests

Jest or Detox files the repo already contains, including `__tests__`.

### Dependency registration

`package.json` dependencies and native module linking the project already declares.

## react

### Entry points

`index` / `main`, root `App`, and route components.

### Tests

Jest, Vitest, or React Testing Library files the repo already contains.

### Dependency registration

`package.json` dependencies and provider composition at the root.

## angular

### Entry points

`main.ts`, `bootstrapApplication` or the root module, and route definitions.

### Tests

`*.spec.ts` files and the runner the repo already uses.

### Dependency registration

`providers` in the application config or root module, plus `package.json` and `angular.json`.

## vue

### Entry points

`main.ts` or `main.js`, root `App`, and the router.

### Tests

Vitest or Jest files the repo already contains.

### Dependency registration

`app.use` plugin registration and `package.json` dependencies.

## blazor

### Entry points

`Program.cs`, `App.razor`, and the router component.

### Tests

bUnit or other test projects the repo already contains.

### Dependency registration

Service registration in `Program.cs` and package references in the project file.

## electron

### Entry points

Main-process entry, preload script, and renderer entry.

### Tests

Test files the repo already runs for the main process or the renderer.

### Dependency registration

`package.json` dependencies and `BrowserWindow` / IPC wiring the project already shows.

## javascript

### Entry points

`package.json` `main` or `bin`, and the server or script file that starts the process.

### Tests

Node test runner, Jest, or other test files the repo already contains.

### Dependency registration

`package.json` dependencies and explicit `require` / `import` of collaborators at the entry.

## java

### Entry points

The main class, a framework application class, and HTTP or message handlers.

### Tests

JUnit classes under the test source set the repo already uses.

### Dependency registration

`pom.xml` or Gradle dependency declarations, and framework configuration types that register collaborators.

## python

### Entry points

The module, application object, or CLI the process starts from (FastAPI, Flask, or a script, as the repo shows).

### Tests

pytest (or another runner) files the repo already contains.

### Dependency registration

`pyproject.toml`, `requirements*.txt`, or the framework's dependency container when the project shows one.

## micropython

### Entry points

Device entry the project declares (`main.py`, `boot.py`, or the port entry the repo shows), with runtime, target, or port evidence already present.

### Tests

Host or device tests the repo already contains for that firmware workflow.

### Dependency registration

Frozen modules, manifests, or package lists the firmware project already declares.

## esp-idf

### Entry points

`app_main` and the component `CMakeLists.txt` files that register sources.

### Tests

Test applications or Unity targets the repo already declares.

### Dependency registration

`idf_component.yml`, Component Manager lockfiles, and `REQUIRES` / `idf_component_register` in CMake.

## arduino

### Entry points

Sketch `setup` / `loop` and libraries the sketch already includes, when Arduino Core or `framework = arduino` evidence is present.

### Tests

Test sketches or host tests the repo already contains.

### Dependency registration

`library.properties`, platform metadata, and library includes the sketch already uses.

## blip-plugin

### Entry points

Plugin scaffold entry, exported commands, and the extension surface the project already ships.

### Tests

Test files the plugin repo already contains.

### Dependency registration

The plugin `package.json` dependencies and extension registration the scaffold already shows.
