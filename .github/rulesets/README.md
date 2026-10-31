# Branch rulesets

Versioned copies of this repository's GitHub rulesets. GitHub stores them in the repository settings; these files record the expected state.

| File | Ruleset | Branch | Allowed merge methods | Required checks |
|------|---------|--------|-----------------------|-----------------|
| `protect-develop.json` | `protect-develop` | `develop` | squash, merge | `validate` |
| `protect-release.json` | `protect-release` | `master` | merge | `release-source` |

Both rulesets block deletion and non-fast-forward updates, require a pull request (no direct commits), and have no bypass actors.

## Apply

Create or update a ruleset from a file. Replace `{owner}/{repo}` and, for updates, the ruleset id:

```bash
gh api -X POST repos/{owner}/{repo}/rulesets --input .github/rulesets/protect-develop.json
gh api -X PUT repos/{owner}/{repo}/rulesets/{ruleset_id} --input .github/rulesets/protect-develop.json
```

List the ids with `gh api repos/{owner}/{repo}/rulesets --jq '.[] | "\(.id) \(.name)"'`.
