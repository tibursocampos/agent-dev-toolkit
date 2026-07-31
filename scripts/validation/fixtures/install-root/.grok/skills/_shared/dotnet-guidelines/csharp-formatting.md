# C# Code Formatting

We standardize on **CSharpier** as the official code formatter for C# in all .NET projects. CSharpier is an opinionated formatter (originally ported from Prettier) that enforces a single consistent style with minimal configuration. We leverage CSharpier as the default formatter and style linter, so that all code is automatically reformatted to a uniform style and any deviations are caught early in development.

Previously we used the built-in `dotnet format` tool, but we found it unreliable. In practice it often produced inconsistent results and sometimes failed to detect existing formatting issues.

## Configuring CSharpier

- **Version:** We use CSharpier across our projects. Install it as a .NET tool (locally or globally) and run it with `csharpier` or via your IDE integration.
- **Usage:** Integrate CSharpier into your build or CI process to fail on unformatted code. For example, the CI pipeline can run `csharpier check . --log-level Debug` or check for diffs after formatting, ensuring that no unformatted code is merged.
- **Editor Integration:** Configure your editor (e.g. VS Code, Rider, Visual Studio) to use CSharpier as the default C# formatter. This way, saving a file automatically applies the official style.

## Git Pre-Commit Hook (Husky)

To catch formatting issues before commits, we set up a Git pre-commit hook using Husky.Net. 

1. **Install Husky:** In the repository root, ensure you have a .NET tool manifest. Then install Husky and CSharpier with:
   ```bash
   dotnet new tool-manifest
   dotnet tool install husky
   dotnet husky install
   dotnet tool install csharpier
   ```

2. **Configure the Task Runner:** Edit the file `.husky/task-runner.json` and add a CSharpier task. For example:
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

## Coding Formatting and Layout Rules (Microsoft Learn)

To keep code highly readable across all platforms (including mobile screens, diff tools, and code-review viewers), enforce the following layout rules:

* **Indentation:** Use four spaces for indentation. Do not use tab characters.
* **Line Length Limit:** Limit lines to **65 characters** to enhance code readability. Break long statements into multiple lines when necessary, breaking before binary operators.
* **Braces Style (Allman):** Use the "Allman" style for braces: both opening and closing braces must be placed on their own new lines, matching the current indentation level.
* **One Statement Per Line:** Write only one statement per line and only one declaration per line.
* **Blank Lines:** Add at least one blank line between method definitions and property definitions.
* **Parentheses:** Use parentheses to make clauses in boolean and arithmetic expressions apparent:
  ```csharp
  if ((startX > endX) && (startX > previousX))
  {
      // Take appropriate action.
  }
  ```

