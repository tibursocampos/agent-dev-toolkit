# Security policy

This repository is a **public, read-only** toolkit (clone/fork OK; no upstream community PRs). See [CONTRIBUTING.md](CONTRIBUTING.md) and [docs/REPO_GOVERNANCE.md](docs/REPO_GOVERNANCE.md).

## Reporting a vulnerability

**Do not** open a public GitHub Issue for security vulnerabilities.

Preferred channels (use the first that is available on this repository):

1. **GitHub Private vulnerability reporting (PVR) / Security Advisories** — when enabled, use **Security → Advisories → Report a vulnerability** (or **Report a vulnerability** on the Security tab).
2. **Contact repository owners via GitHub** — if PVR is not enabled yet, contact an owner through their **GitHub profile**. Do **not** invent, guess, or publish a security mailbox that does not exist.

No dedicated security email is published for this repository.

## Maintainer checklist (first publish / repo settings)

Before treating channel 1 as available, maintainers must:

1. Enable **Private vulnerability reporting** for this repository (**Settings → Code security and analysis → Private vulnerability reporting**).
2. Confirm the Security tab shows **Report a vulnerability** for reporters who are not collaborators.
3. Keep this file honest: do not invent a security email; if a real mailbox is later designated, update this section with that address only.

## What to include

- Description of the issue and potential impact
- Steps to reproduce (PoC if safe to share privately)
- Affected paths (skills, scripts, adapters, docs) when known
- Your preferred contact for follow-up

## Out of scope for Issues

GitHub **Issues** are for **non-security bug reports only** (broken sync, validation failures, incorrect docs, runtime errors). See [CONTRIBUTING.md](CONTRIBUTING.md). Feature requests and contribution threads are not accepted.

## Safe disclosure expectation

Please give maintainers reasonable time to assess and address a report before any public disclosure.
