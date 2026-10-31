#!/usr/bin/env sh
# OpenHands SessionStart hook: emit the spawn digest as additional context.
# Fail-open: any problem exits 0 without output. Does not configure Automation Server, sandbox, models, or secrets.
dir=$(cd "$(dirname "$0")" 2>/dev/null && pwd) || exit 0
digest=""
for candidate in \
  "$dir/../../.agents/skills/_shared/agents/SPAWN-DIGEST.md" \
  "$dir/../../skills/_shared/agents/SPAWN-DIGEST.md" \
  "$dir/../../../../core/skills/_shared/agents/SPAWN-DIGEST.md"
do
  if [ -f "$candidate" ]; then
    digest=$candidate
    break
  fi
done
[ -n "$digest" ] || exit 0
text=$(cat "$digest" 2>/dev/null) || exit 0
[ -n "$text" ] || exit 0
escaped=$(printf '%s' "$text" | tr -d '\r' | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | awk 'BEGIN{ORS="\\n"} {print}')
printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$escaped"
exit 0
