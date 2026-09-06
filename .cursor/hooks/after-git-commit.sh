#!/bin/bash
# After Shell tool use: if a git commit touched rules/docs (or Swift while docs exist), remind alignment.
set -euo pipefail

input=$(cat)

# Only act on successful git commit commands
cmd=$(echo "$input" | /usr/bin/python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("command") or d.get("tool_input",{}).get("command") or "")' 2>/dev/null || true)
if ! echo "$cmd" | grep -Eq 'git[[:space:]]+commit'; then
  echo '{}'
  exit 0
fi

changed=$(git diff-tree --no-commit-id --name-only -r HEAD 2>/dev/null || true)

needs_align=0
if echo "$changed" | grep -E -q '^(\.cursor/rules/|docs/|\.cursor/skills/wedge-keep-aligned/)'; then
  needs_align=1
fi
if echo "$changed" | grep -E -q '\.swift$'; then
  if [ -d docs ] && find docs -type f 2>/dev/null | grep -q .; then
    needs_align=1
  fi
fi

if [ "$needs_align" -eq 1 ]; then
  cat <<'EOF'
{
  "additional_context": "Git commit landed. If this commit changed product behavior or docs/rules, run wedge-keep-aligned so plans, docs, and .cursor/rules stay consistent. Skip inventing new roadmap docs unless the user asked."
}
EOF
else
  echo '{}'
fi
exit 0
