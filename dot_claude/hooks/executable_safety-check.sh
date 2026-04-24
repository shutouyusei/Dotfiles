#!/bin/bash
# Safety check hook for Claude Code
# Runs before every Bash tool invocation
# Exit 0 = allow, Exit 2 = block

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

DANGEROUS_PATTERNS=(
  "rm -rf /"
  "rm -rf ~"
  "rm -rf \.\."
  "rm -rf \*"
  "git push.*--force"
  "git push.*-f[^i]"
  "git reset --hard"
  "git clean -fd"
  "git checkout -- \."
  "DROP TABLE"
  "DROP DATABASE"
  "TRUNCATE"
  "mkfs\."
  "dd if="
  "> /dev/sd"
  "chmod -R 777"
  "curl.*\|\s*bash"
  "curl.*\|\s*sh\b"
  "wget.*\|\s*bash"
  "wget.*\|\s*sh\b"
  ":(){ :|:& };:"
  "shutdown"
  "reboot"
  "init 0"
  "systemctl stop"
  "kill -9 -1"
  "pkill -9"
)

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qiE "$pattern"; then
    echo "BLOCKED: dangerous command pattern '$pattern' detected" >&2
    exit 2
  fi
done

exit 0
