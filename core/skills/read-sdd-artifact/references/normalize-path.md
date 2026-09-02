## Normalize input path

1. Trim whitespace; reject if empty → `empty_path`.
2. Normalize separators to `/`.
3. Reject OS absolute (`^[A-Za-z]:/` or leading `\\`) and user-home InstallRoot embeds → `absolute_path_forbidden`.
4. Reject any `..` segment → `path_traversal`.
5. Require a path-**segment** `features/` (`(^|/)features/`, not substring `myfeatures/`) with a following `NNN-slug` → else `outside_features`.
6. Match one canonical kind table row (see `references/envelope-schema.md`) → else `unsupported_kind`.
7. Resolve against repo (or global classic) root; missing file → `not_found` (still **no** envelope).
