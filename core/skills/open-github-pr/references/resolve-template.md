## Resolve PR body template

Search the **target repository** (cwd), then fall back to this skill’s templates.

**Feature mode** (first match wins):

1. `.github/PULL_REQUEST_TEMPLATE.md`
2. `.github/pull_request_template.md`
3. Any `.md` under `.github/PULL_REQUEST_TEMPLATE/` — prefer `feature.md` if it exists; otherwise the first sensible template file
4. Else: `{{TOOLKIT_ROOT}}/skills/open-github-pr/templates/feature-pr.md`

**Release mode** (first match wins):

1. `.github/PULL_REQUEST_TEMPLATE/release.md`
2. Else: `{{TOOLKIT_ROOT}}/skills/open-github-pr/templates/release-pr.md`

Do not invent org-only template APIs. Fill placeholders from git/`gh` data.
