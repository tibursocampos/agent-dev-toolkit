#!/usr/bin/env bash
# Hermes agent-hooks pre_tool_call - path/secrets guard (POSIX).
# Prefer GuardCommon via pwsh; fail-closed when pwsh is absent (align with fail_closed).
set -euo pipefail

payload="$(cat - || true)"
if [[ -z "${payload}" ]]; then
  printf '{}\n'
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PS1_GUARD="${SCRIPT_DIR}/guard-pre-tool.ps1"

if command -v pwsh >/dev/null 2>&1 && [[ -f "${PS1_GUARD}" ]]; then
  printf '%s' "${payload}" | pwsh -NoProfile -File "${PS1_GUARD}"
  exit $?
fi

if command -v powershell >/dev/null 2>&1 && [[ -f "${PS1_GUARD}" ]]; then
  printf '%s' "${payload}" | powershell -NoProfile -File "${PS1_GUARD}"
  exit $?
fi

# Fail-closed: cannot evaluate GuardCommon without PowerShell.
printf '{"action":"block","message":"pwsh unavailable; Hermes agent-hooks guard fail-closed"}\n'
exit 2
