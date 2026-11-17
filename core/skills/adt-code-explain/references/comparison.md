# Git comparison

Load this file when the pass compares `source` and `target`. It names three comparisons. It declares no integer confirmation threshold and no confirmation prompt before reading.

Apply the optional folder prefix from the skill Inputs when `path` is present. Keep the three commands distinct.

## Working tree versus HEAD

When `source` is `working-tree` and `target` is `HEAD`, list the two sets separately:

- Unstaged changes: `git diff`
- Staged changes: `git diff --cached`

Do not replace those two commands with one `git diff HEAD`. That single command mixes staged and unstaged changes.

## Branch versus branch

When `source` and `target` are both branch refs, the comparison is three dots:

```text
git diff <target>...<source>
```

## Working tree versus another branch

When `source` is `working-tree` and `target` is a branch other than the current `HEAD`, the comparison is two dots:

```text
git diff <target>
```

Uncommitted work is included.

## Empty diff

When any of the three forms returns an empty diff, the report states that there is no change. Do not describe behavior that is not in the diff. Do not start a build. Do not start tests.
