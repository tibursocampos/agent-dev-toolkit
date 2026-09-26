# Commands

Run the command the stack skill already documents. Do not invent another.

| Stack | Command | Source |
|-------|---------|--------|
| `python-developer` | `pytest` | `python-developer/references/execute-flow.md` |
| `dotnet-developer` | `dotnet test --no-build` after the build | `dotnet-developer/references/execute-flow.md` |
| `blazor-developer` | `dotnet test` | `blazor-developer/references/execute-flow.md` |
| `java-developer` | `mvn test` when `pom.xml` exists; `./gradlew test` when `build.gradle` or `build.gradle.kts` exists | `java-developer/references/execute-flow.md` |
| `angular-developer` | `ng test` | `angular-developer/references/execute-flow.md` |
| `react-developer`, `vue-developer`, `javascript-developer`, `react-native-developer` | `npm test` | that skill's `references/execute-flow.md` |
| `electron-developer` | none | `electron-developer/references/execute-flow.md` has no test command |
| `blip-plugin-developer` | same as `react-developer` | — |

When the PLAN asks for coverage, and the stack is `dotnet-developer` or `blazor-developer`, call `test-coverage` after the test command. Without that sentence in the PLAN, do not call Coverlet.

If an Angular project has no test script, stop `stack_test_command_missing`. Do not switch to `npm test` on your own.

If `package.json` has no `test` script for a Node stack in the table, stop `stack_test_command_missing`.

`electron-developer`: stop `stack_test_command_missing`. Do not invent a manual smoke run and call it pass.

No stack detected: stop `stack_not_detected` and ask. Do not run a generic test.
