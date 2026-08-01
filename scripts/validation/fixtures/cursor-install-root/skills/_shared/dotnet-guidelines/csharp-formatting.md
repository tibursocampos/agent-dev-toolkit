# C# Code Formatting

We standardize on **CSharpier** as the official code formatter for C# in all .NET projects. CSharpier is an opinionated formatter (originally ported from Prettier) that enforces a single consistent style with minimal configuration. We leverage CSharpier as the default formatter so that all code is automatically reformatted to a uniform style and any deviations are caught early in development.

Previously we used the built-in `dotnet format` tool for whitespace, but it often conflicted with CSharpier and produced inconsistent results. **Do not** use `dotnet format` (whitespace) as the formatting gate when CSharpier is configured. Use EditorConfig + Roslyn analyzers for **semantic** rules (naming, unused usings, NRT); disable IDE0055 / whitespace checks that fight CSharpier.

## Configuring CSharpier

- **Version:** Install CSharpier as a .NET tool (locally or globally) and run it with `csharpier` or via IDE integration.
- **Usage:** Integrate CSharpier into build or CI to fail on unformatted code, for example `csharpier check .`.
- **Editor Integration:** Configure the editor (VS Code, Rider, Visual Studio) to use CSharpier as the default C# formatter so save applies the official style.
- **Optional:** teams may set `printWidth` (for example `150`) in `.csharpierrc` to align visual wrapping with the signature/invocation character threshold in `csharp-patterns.md`. Default CSharpier print width is ~100; that is fine when the agent/review MUST of **5 parameters / 150 characters** still applies.

## Method signatures and invocations

Parameter count and the **150-character** inline threshold are **not** owned by CSharpier. Follow **`csharp-patterns.md`** (§ Method signatures and invocations):

- Inline: up to **5** parameters **and** full line **≤ 150** characters.
- Otherwise: one parameter per line.

## Git Pre-Commit Hook (Husky)

To catch formatting issues before commits, use a Git pre-commit hook with Husky.Net.

1. **Install Husky:** In the repository root, ensure you have a .NET tool manifest. Then install Husky and CSharpier with:
   ```bash
   dotnet new tool-manifest
   dotnet tool install husky
   dotnet husky install
   dotnet tool install csharpier
   ```

2. **Configure the Task Runner:** Edit `.husky/task-runner.json` and add a CSharpier task. For example:
   ```json
   {
     "tasks": [{
       "name": "Run csharpier",
       "command": "csharpier",
       "args": ["format", "${staged}"],
       "include": [
          "**/*.cs",
          "**/*.csx",
          "**/*.csproj",
          "**/*.props",
          "**/*.targets"
       ]
     }]
   }
   ```

3. **Test the Hook:** Run `dotnet husky run` to verify that the CSharpier task executes correctly.

4. **Attach to Project:** To automate setup for all developers, attach Husky to your project file:
   ```bash
   dotnet husky attach <path-to-your-project>.csproj
   ```

5. **Enable Pre-Commit:** Once the task runner is working, add the actual pre-commit hook:
   ```bash
   dotnet husky add pre-commit -c "dotnet husky run"
   ```

These steps ensure that any C# code committed to the repository is formatted by CSharpier beforehand.

## Layout basics (owned by CSharpier)

- **Indentation:** four spaces (no tabs) - CSharpier default.
- **Braces:** CSharpier output (typically opening brace on the same line) - do not enforce Allman style against the formatter.
- **One statement per line** and blank lines between members as CSharpier produces.
- Prefer parentheses that make boolean/arithmetic clauses clear when writing by hand; let CSharpier normalize whitespace.
