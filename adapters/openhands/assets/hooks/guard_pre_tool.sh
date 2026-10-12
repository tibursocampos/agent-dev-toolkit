#!/usr/bin/env sh
# OpenHands PreToolUse path/secrets guard.
# Catch-all matcher delegates every tool surface to the provider classifier. Deny = decision deny + exit 2.
# Prefer colocated guard_pre_tool.ps1 + GuardCommon when pwsh is available.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
PS1_HELPER="$SCRIPT_DIR/guard_pre_tool.ps1"

INPUT=$(cat)

if command -v pwsh >/dev/null 2>&1 && [ -f "$PS1_HELPER" ]; then
  printf '%s' "$INPUT" | pwsh -NoProfile -File "$PS1_HELPER"
  exit $?
fi

# The host owns authorization; missing optional Toolkit hook runtime must not deny.
printf '%s\n' '{"decision":"allow","reason":"Toolkit hook unavailable; host authorization remains active"}'
exit 0
