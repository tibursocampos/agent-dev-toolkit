# Commands

Run the command the stack skill already documents. Do not invent another.

| Stack | Command | Source |
|-------|---------|--------|
| `adt-python-developer` | `pytest` | `adt-python-developer/references/execute-flow.md` |
| `adt-dotnet-developer` | `dotnet test --no-build` after the build | `adt-dotnet-developer/references/execute-flow.md` |
| `adt-blazor-developer` | `dotnet test` | `adt-blazor-developer/references/execute-flow.md` |
| `adt-java-developer` | `mvn test` when `pom.xml` exists; `./gradlew test` when `build.gradle` or `build.gradle.kts` exists | `adt-java-developer/references/execute-flow.md` |
| `adt-angular-developer` | `ng test` | `adt-angular-developer/references/execute-flow.md` |
| `adt-react-developer`, `adt-vue-developer`, `adt-javascript-developer`, `adt-react-native-developer` | `npm test` | that skill's `references/execute-flow.md` |
| `adt-electron-developer` | none | `adt-electron-developer/references/execute-flow.md` has no test command |
| `adt-blip-plugin-developer` | same as `adt-react-developer` | — |

When the PLAN asks for coverage, and the stack is `adt-dotnet-developer` or `adt-blazor-developer`, call `adt-test-coverage` after the test command. Without that sentence in the PLAN, do not call Coverlet.

If an Angular project has no test script, stop `stack_test_command_missing`. Do not switch to `npm test` on your own.

If `package.json` has no `test` script for a Node stack in the table, stop `stack_test_command_missing`.

`adt-electron-developer`: stop `stack_test_command_missing`. Do not invent a manual smoke run and call it pass.

No stack detected: stop `stack_not_detected` and ask. Do not run a generic test.
