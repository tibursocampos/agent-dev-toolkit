# Upstream notice

Selected files under `reference/` and `agents/` are adapted from [pbakaus/impeccable](https://github.com/pbakaus/impeccable) `skill/reference` and `skill/agents`.

Copyright 2025 Paul Bakaus. Licensed under the Apache License, Version 2.0: https://www.apache.org/licenses/LICENSE-2.0

The rest of agent-dev-toolkit stays under the repository MIT license.

Modifications: the toolkit harness does not ship the Impeccable engine launcher, `skill/scripts/bin`, `skill/scripts/data/font-index.json`, or `browser-bundle`. Detector calls use `npx impeccable detect`. Install, live, and hooks still require an explicit user sim. Each vendored file starts with an HTML comment that states this.

Not vendored: repository `scripts/` and `scripts/lib` (their build), `docs/` (their site), root `DESIGN.md` (their example product), `browser-bundle`, and the live-browser script bundle.
