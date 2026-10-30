<!-- Maintainer-only: this repo does not accept community PRs. -->
<!-- Default base: develop. Release: develop → master/main. -->

## Summary

<!-- What changed and why (1-3 bullets). -->

-

## Base branch

- [ ] Feature / fix work targets **`develop`**
- [ ] Release PR is **`develop` → `master` or `main`** (not a feature branch into release)

## Test plan

Parity with `.github/workflows/validate-toolkit.yml` (as applicable to the change):

- [ ] `.\scripts\validation\validate-core.ps1` passes locally (alias: `validate-all.ps1`)
- [ ] `.\scriptsalidation\Assert-AdapterPublish.ps1` (publish, layout and uninstall checks; use `-Adapter <id>` for the adapter touched)
- [ ] `.\scripts\validation\Assert-SyncAllowUserHomeForward.ps1` (when sync/home-guard paths change)
- [ ] CI smokes relevant to the change pass locally:
  - [ ] `Invoke-AdapterCiSmoke -Adapter <id>` for each adapter touched
- [ ] New/renamed skills appear in `docs/SKILLS.md` and README Skills table (**36** skills)
- [ ] No secrets or org-only credentials in the diff
- [ ] No new links to `features/**` story paths in public docs (SPAWN: `docs/SPAWN.md` / `core/skills/_shared/agents/SPAWN.md`)

## Notes

<!-- Optional: migration notes. -->
