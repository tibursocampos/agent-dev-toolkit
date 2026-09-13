## Code smells analysis

* Read the target file. Identify code smells:
  * Methods or functions exceeding 30 lines.
  * Deep nesting (more than 3 levels of indentation).
  * Magic strings or hardcoded parameters.
  * Duplicate blocks of code within the file.
  * Violation of SOLID principles (e.g., class doing too many things).
  * Structure/quality gaps vs `{{TOOLKIT_ROOT}}/skills/_shared/code-guidelines/principles/structure-and-quality.md` (architecture vs style, language mirror/ask, constants, blank-spam, one primary type/file).
  * For C#: also check `csharp-patterns.md` (signatures, named constants, blank lines, construction).
* Present a summary of identified smells.
