#!/usr/bin/env sh
# Thin Linux/macOS wrapper for toolkit Release bootstrap (HTTPS + SHA256 → extract → toolkit.ps1).
# Forwards all args to bootstrap.ps1 via pwsh. Requires PowerShell 7+ (pwsh) on PATH.
# Must path without this wrapper: pwsh -NoProfile -File ./scripts/bootstrap/bootstrap.ps1 …
# Default after extract: interactive scripts/toolkit.ps1. Optional -DirectSync → sync-agent.ps1.
# No gh CLI, Node, or compiled .exe bootstrap artifact required.
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)

if ! command -v pwsh >/dev/null 2>&1; then
  echo "bootstrap.sh: pwsh not found. Install PowerShell 7+ or run: pwsh -NoProfile -File \"${SCRIPT_DIR}/bootstrap.ps1\" …" >&2
  exit 1
fi

exec pwsh -NoProfile -File "${SCRIPT_DIR}/bootstrap.ps1" "$@"
