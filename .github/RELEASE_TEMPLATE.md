# Release notes

Published GitHub Releases use this shape. `.github/workflows/release.yml` reads the approved `Highlights` from the merged release PR, then fills Included work with application PRs associated with commits between the previous release tag and promoted commit. It omits the develop-to-master promotion PR and generated develop reconciliation PRs. The Changelog links the previous release tag to this release. Do not publish the GitHub "What's Changed" list as the body.

The tag is `vMAJOR.MINOR.PATCH`. Older tags `v.1.1.0` and `1.4.0` are legacy names, not the pattern.

## Highlights

Operator-facing changes supplied in the merged release PR. One bullet per change.

## Included work

Application pull requests associated with commits in the release range (promotion and reconciliation PRs are omitted):

- [PR #N: title](https://github.com/tibursocampos/agent-dev-toolkit/pull/N)

## Release assets

`publish-release-bootstrap.yml` attaches these files when the release is published:

- `agent-dev-toolkit.zip`
- `agent-dev-toolkit.zip.sha256`
- `bootstrap.bat`
- `bootstrap.ps1`
- `bootstrap.sh`

## Changelog

Compare link from the previous tag to this tag.
