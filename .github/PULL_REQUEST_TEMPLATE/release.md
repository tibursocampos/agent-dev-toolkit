<!-- Maintainer-only: this repo does not accept community PRs. -->
<!-- Release template: develop → master/main. Prefer this over the default feature template for release PRs. -->
<!-- `/open-github-pr` release mode can auto-fill the Included changes table. -->

## Summary

<!-- Release window: what is shipping from `develop` → `master`/`main` (1-3 bullets). -->

-

## Release decision

<!-- Required: choose yes or no. Version must be the next MAJOR.MINOR.PATCH when yes; use N/A when no. -->

Create release: no
Version: N/A

## Highlights

<!-- Short release highlights copied into the published GitHub Release notes. One bullet per highlight. -->

-

## Included changes

<!-- Application PRs merged into `develop` since the last release; omit the release promotion and generated reconciliation PRs. `/open-github-pr` release mode can auto-fill this table. -->

| PR | Title | Author | Merged |
| --- | --- | --- | --- |
| | | | |

## Commits

<!-- Paste a short `git log` summary of commits on `develop` not in the base (`master`/`main`). -->

```text
# Example: git log --oneline origin/master..origin/develop
```

-

## Base branch

- [ ] Release PR is **`develop` → `master` or `main`** (not a feature branch into release)

## Test plan

Parity with `.github/workflows/validate-toolkit.yml` (as applicable; N/A is OK for docs-only adapter smokes):

- [ ] CI / `.\scripts\validation\validate-core.ps1` passes (alias: `validate-all.ps1`)
- [ ] Relevant adapter CI smokes pass locally, or **N/A** (docs-only / no adapter impact)
- [ ] No secrets or org-only credentials in the release diff

## Notes

<!-- Optional: rollout, migration, or follow-ups. -->
