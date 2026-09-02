## Update resource bundles and refactor code

### Update resource bundles

* Write or append the translations to the resource files:
  * JSON bundles: add key/value fields in `en.json`, `pt.json`, etc.
  * Dotnet XML: add `<data name="Key"><value>Text</value></data>` nodes in target `.resx` files.
* Ensure keys are sorted alphabetically to prevent duplicate entries and maintain layout.

### Code refactoring

* Replace the hardcoded string literal in the code file with the dynamic localization call.
* Inject the localizer dependency if it is not already available (e.g. adding `private readonly IStringLocalizer<T> _localizer` to a C# constructor, or `const { t } = useTranslation()` in a React component).
