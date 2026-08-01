# InstallRoot fixture (in-repo)

Seed directory used by smoke harness and sync/validate orchestration as a safe
`InstallRoot`. Paths resolve under the toolkit repo — never under `%USERPROFILE%`
unless `-AllowUserHome` is set explicitly.

Do not sync this tree to a live agent home. CI and local smokes must use this
fixture (or another path under the repo root).

Runtime marker: `.smoke-harness-marker` may be written by `Invoke-SmokeHarness.ps1`
and is safe to delete; it is not a skill golden fixture.
