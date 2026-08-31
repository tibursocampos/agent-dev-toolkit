#!/usr/bin/env sh
# OpenHands PreToolUse path/secrets guard.
# Matchers: write|terminal (and file_editor aliases). Deny = decision deny + exit 2.
# Prefer colocated guard_pre_tool.ps1 + GuardCommon when pwsh is available.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
PS1_HELPER="$SCRIPT_DIR/guard_pre_tool.ps1"

INPUT=$(cat)

if command -v pwsh >/dev/null 2>&1 && [ -f "$PS1_HELPER" ]; then
  printf '%s' "$INPUT" | pwsh -NoProfile -File "$PS1_HELPER"
  exit $?
fi

if command -v powershell >/dev/null 2>&1 && [ -f "$PS1_HELPER" ]; then
  printf '%s' "$INPUT" | powershell -NoProfile -File "$PS1_HELPER"
  exit $?
fi

# Fail-closed when PowerShell is unavailable (cannot evaluate GuardCommon).
printf '%s\n' '{"decision":"deny","reason":"pwsh unavailable; OpenHands guard fail-closed"}'
exit 2
