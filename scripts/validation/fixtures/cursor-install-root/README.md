# Cursor InstallRoot fixture (in-repo)

Empty seed used by Cursor adapter publish/smoke tests as a safe
`InstallRoot` (layout equivalent to `~/.cursor`).

Paths resolve under the toolkit repo — never under `%USERPROFILE%` unless
`-AllowUserHome` is set explicitly.

Do not sync this tree to a live Cursor home. CI and local smokes must use this
fixture (or another path under the repo root).

Published artifacts (skills, rules, hooks, …) may appear here during tests and
are safe to delete between runs.
