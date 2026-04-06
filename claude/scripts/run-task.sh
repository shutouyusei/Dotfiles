#!/bin/bash
# run-task.sh — Launch Claude Code to autonomously execute GitHub Issues
#
# Usage:
#   ./run-task.sh <issue_number>              Single task
#   ./run-task.sh 17 13 14 15                 Multiple tasks (sequential)
#   ./run-task.sh 13 14 15 --parallel         Multiple tasks (parallel, default 3 concurrent)
#   ./run-task.sh 13 14 15 --parallel 5      Multiple tasks (parallel, 5 concurrent)
#   ./run-task.sh 13 --max-turns 80           Custom max turns

set -euo pipefail

# Load environment (bashrc may not be sourced in nohup context)
if [ -f "$HOME/.bashrc" ]; then
  source "$HOME/.bashrc" 2>/dev/null || true
fi

# Parse arguments: separate issue numbers from options
ISSUE_NUMBERS=()
MAX_TURNS=40
PARALLEL=false
MAX_CONCURRENT=3

while [[ $# -gt 0 ]]; do
  case $1 in
    --max-turns)
      MAX_TURNS="$2"
      shift 2
      ;;
    --parallel)
      PARALLEL=true
      # Check if next arg is a number (custom concurrency)
      if [[ "${2:-}" =~ ^[0-9]+$ ]] && [ "${2:-0}" -gt 0 ]; then
        MAX_CONCURRENT="$2"
        shift
      fi
      shift
      ;;
    [0-9]*)
      ISSUE_NUMBERS+=("$1")
      shift
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Usage: run-task.sh <issue_numbers...> [--parallel [N]] [--max-turns N]" >&2
      exit 1
      ;;
  esac
done

if [ ${#ISSUE_NUMBERS[@]} -eq 0 ]; then
  echo "Usage: run-task.sh <issue_numbers...> [--parallel [N]] [--max-turns N]" >&2
  exit 1
fi

# Must be run from a git repository root
WORK_DIR="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "ERROR: Not inside a git repository. Run this from your project directory." >&2
  exit 1
}
cd "$WORK_DIR"

# Verify environment
if [ -z "${DISCORD_WEBHOOK_URL:-}" ]; then
  echo "WARNING: DISCORD_WEBHOOK_URL is not set. Notifications will not be sent." >&2
fi

if ! gh auth status &>/dev/null; then
  echo "ERROR: gh is not authenticated. Run 'gh auth login' first." >&2
  exit 1
fi

# Verify all issues exist before starting
for ISSUE in "${ISSUE_NUMBERS[@]}"; do
  if ! gh issue view "$ISSUE" --json number &>/dev/null; then
    echo "ERROR: Issue #$ISSUE not found in $(gh repo view --json nameWithOwner -q .nameWithOwner)." >&2
    exit 1
  fi
done

LOG_DIR="$HOME/.claude/logs"
mkdir -p "$LOG_DIR"

TOTAL=${#ISSUE_NUMBERS[@]}
MODE="sequential"
if [ "$PARALLEL" = true ] && [ "$TOTAL" -gt 1 ]; then
  MODE="parallel"
fi
echo "Queued $TOTAL task(s): ${ISSUE_NUMBERS[*]} (max $MAX_TURNS turns each, $MODE)"

# Notify queue start
if [ -n "${DISCORD_WEBHOOK_URL:-}" ] && [ "$TOTAL" -gt 1 ]; then
  curl -s -X POST "$DISCORD_WEBHOOK_URL" \
    -H "Content-Type: application/json" \
    -d "{\"content\": \"📋 Task queue started ($MODE): #$(IFS=', #'; echo "${ISSUE_NUMBERS[*]}") ($TOTAL tasks)\"}" \
    > /dev/null
fi

# Run a single task — used by both sequential and parallel modes
run_task() {
  local ISSUE="$1"
  local POSITION="$2"
  local LOG_FILE="$LOG_DIR/task-${ISSUE}-$(date +%Y%m%d-%H%M%S).log"

  echo "=== Task $POSITION/$TOTAL: Issue #$ISSUE ==="

  # Check if all dependencies are resolved
  local ISSUE_BODY
  ISSUE_BODY=$(gh issue view "$ISSUE" --json body -q '.body')
  local DEPS
  DEPS=$(echo "$ISSUE_BODY" | grep -oP '#\K[0-9]+(?= must be completed)' || true)
  local BLOCKED=false

  for DEP in $DEPS; do
    local STATE
    STATE=$(gh issue view "$DEP" --json state -q '.state')
    if [ "$STATE" != "CLOSED" ]; then
      echo "Task #$ISSUE is blocked by #$DEP (still $STATE). Skipping."
      echo "It will auto-start when #$DEP's PR is merged."
      BLOCKED=true
      break
    fi
  done

  if [ "$BLOCKED" = true ]; then
    if [ -n "${DISCORD_WEBHOOK_URL:-}" ]; then
      curl -s -X POST "$DISCORD_WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d "{\"content\": \"⏸️ Task #$ISSUE skipped (blocked by dependency). Will auto-start when dependency PR is merged.\"}" \
        > /dev/null
    fi
    return 0
  fi

  cd "$WORK_DIR"

  # Run Claude Code
  claude -p "/execute $ISSUE" \
    --allowedTools "Edit,Write,Read,Glob,Grep,Bash,Agent" \
    --max-turns "$MAX_TURNS" \
    > "$LOG_FILE" 2>&1

  local EXIT_CODE=$?
  echo "Task #$ISSUE finished (exit code: $EXIT_CODE). Log: $LOG_FILE"

  if [ $EXIT_CODE -ne 0 ]; then
    if [ -n "${DISCORD_WEBHOOK_URL:-}" ]; then
      curl -s -X POST "$DISCORD_WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d "{\"content\": \"🛑 Task #$ISSUE failed (exit $EXIT_CODE).\"}" \
        > /dev/null
    fi
    return $EXIT_CODE
  fi
}

# === Parallel execution ===
if [ "$PARALLEL" = true ] && [ "$TOTAL" -gt 1 ]; then
  echo "Concurrency limit: $MAX_CONCURRENT"
  PIDS=()
  FAILED=0

  for i in "${!ISSUE_NUMBERS[@]}"; do
    ISSUE="${ISSUE_NUMBERS[$i]}"
    POSITION=$((i + 1))

    # Wait if we've reached the concurrency limit
    while [ ${#PIDS[@]} -ge "$MAX_CONCURRENT" ]; do
      NEW_PIDS=()
      for pid in "${PIDS[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
          NEW_PIDS+=("$pid")
        else
          if ! wait "$pid"; then
            FAILED=$((FAILED + 1))
          fi
        fi
      done
      PIDS=("${NEW_PIDS[@]}")
      if [ ${#PIDS[@]} -ge "$MAX_CONCURRENT" ]; then
        sleep 5
      fi
    done

    run_task "$ISSUE" "$POSITION" &
    PIDS+=($!)
  done

  # Wait for remaining
  for pid in "${PIDS[@]}"; do
    if ! wait "$pid"; then
      FAILED=$((FAILED + 1))
    fi
  done

  echo ""
  if [ "$FAILED" -eq 0 ]; then
    echo "=== All $TOTAL tasks completed ==="
  else
    echo "=== $FAILED/$TOTAL tasks failed ==="
  fi

  if [ -n "${DISCORD_WEBHOOK_URL:-}" ]; then
    if [ "$FAILED" -eq 0 ]; then
      curl -s -X POST "$DISCORD_WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d "{\"content\": \"✅ All $TOTAL tasks completed (parallel): #$(IFS=', #'; echo "${ISSUE_NUMBERS[*]}")\"}" \
        > /dev/null
    else
      curl -s -X POST "$DISCORD_WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d "{\"content\": \"⚠️ $FAILED/$TOTAL tasks failed (parallel): #$(IFS=', #'; echo "${ISSUE_NUMBERS[*]}")\"}" \
        > /dev/null
    fi
  fi

  [ "$FAILED" -eq 0 ] || exit 1

# === Sequential execution (default) ===
else
  for i in "${!ISSUE_NUMBERS[@]}"; do
    ISSUE="${ISSUE_NUMBERS[$i]}"
    POSITION=$((i + 1))

    echo ""
    run_task "$ISSUE" "$POSITION" || {
      echo "Task #$ISSUE failed. Stopping queue." >&2
      exit 1
    }
  done

  echo ""
  echo "=== All $TOTAL tasks completed ==="

  if [ -n "${DISCORD_WEBHOOK_URL:-}" ] && [ "$TOTAL" -gt 1 ]; then
    curl -s -X POST "$DISCORD_WEBHOOK_URL" \
      -H "Content-Type: application/json" \
      -d "{\"content\": \"✅ All $TOTAL tasks completed: #$(IFS=', #'; echo "${ISSUE_NUMBERS[*]}")\"}" \
      > /dev/null
  fi
fi
