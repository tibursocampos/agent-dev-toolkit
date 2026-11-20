## Normalize input path

For a known candidate, run the published read-only `{{TOOLKIT_ROOT}}/scripts/runtime/Resolve-SddSourceContext.ps1` with `-PortablePath`, `-RepoRoot` (active workspace), `-SddRoot` (effective SDD root from `STORAGE-RESOLUTION.md`) and `-Layout classic|delivery` selected by the caller. Use `Layout=classic` for Classic/O3 artifacts and `Layout=delivery` for Delivery plans. If the script is unavailable, apply the same rules below. Use the resolved absolute path only for local reads. Pass only the envelope in a handoff, and treat the resolution result as identity rather than authorization.

1. Trim whitespace; reject if empty → `empty_path`.
2. Normalize separators to `/`.
3. Reject OS-absolute and drive-relative paths (`^[A-Za-z]:` or a slash-rooted path after normalization) → `absolute_path_forbidden`.
4. Reject any `..` segment → `path_traversal`.
5. Require a path-**segment** `features/` (`(^|/)features/`, not substring `myfeatures/`) with a following `NNN-slug` → else `outside_features`.
6. Match the selected layout in `references/envelope-schema.md` → else `unsupported_kind`. Reject dot segments, empty components and invalid path characters.
7. Resolve the active repository's `repositories[$Cwd].classic` from the effective InstallRoot manifest per `STORAGE-RESOLUTION.md`. Require the portable prefix for the configured mode: `features/` in `repository`, or the prefix mapped from this exact `classic.path` in `global`. Resolve only under that manifest-selected feature root. Resolve symlink/junction targets before reading and reject escapes. Missing/invalid manifest, unsupported mode, mismatched global prefix, or an escaped `classic.path` is a storage-resolution failure; never fall back to another root.
8. Treat `features_versioned` as Git tracking policy only. Use direct filesystem access for the canonical path so a present repository artifact remains readable when Git ignores `features/`; do not use `git ls-files` or another tracked-file enumeration.
9. In `global`, a local repository copy is a decoy. In either mode, sibling presence/content cannot change `invocation_context` or promote a sibling to authoritative input. Missing file → `not_found` (still **no** envelope).
