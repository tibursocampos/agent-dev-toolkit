## Normalize input path

1. Trim whitespace; reject if empty → `empty_path`.
2. Normalize separators to `/`.
3. Reject OS absolute (`^[A-Za-z]:/` or leading `\\`) and user-home InstallRoot embeds → `absolute_path_forbidden`.
4. Reject any `..` segment → `path_traversal`.
5. Require a path-**segment** `features/` (`(^|/)features/`, not substring `myfeatures/`) with a following `NNN-slug` → else `outside_features`.
6. Match one canonical kind table row (see `references/envelope-schema.md`) → else `unsupported_kind`.
7. Resolve the active repository's `repositories[$Cwd].classic` from the effective InstallRoot manifest per `STORAGE-RESOLUTION.md`. Require the portable prefix for the configured mode: `features/` in `repository`, or the prefix mapped from this exact `classic.path` in `global`. Resolve only under that manifest-selected feature root. Missing/invalid manifest, unsupported mode, mismatched global prefix, or an escaped `classic.path` is a storage-resolution failure; never fall back to another root.
8. Treat `features_versioned` as Git tracking policy only. Use direct filesystem access for the canonical path so a present repository artifact remains readable when Git ignores `features/`; do not use `git ls-files` or another tracked-file enumeration.
9. In `global`, a local repository copy is a decoy. In either mode, sibling presence/content cannot change `invocation_context` or promote a sibling to authoritative input. Missing file → `not_found` (still **no** envelope).
