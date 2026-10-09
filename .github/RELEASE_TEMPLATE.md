# Release notes

Published GitHub Releases use this shape. `.github/workflows/release.yml` fills it from commits on `develop` that are not on `master`. Do not publish the GitHub "What's Changed" list as the body.

The tag is `vMAJOR.MINOR.PATCH`. Older tags `v.1.1.0` and `1.4.0` are legacy names, not the pattern.

## Highlights

Operator-facing changes since the previous tag. One bullet per change. Omit sync merges and release pull requests.

## Included work

Pull requests that carried those changes:

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
