#!/bin/bash
# run-research.sh — Autonomously research Linear tasks and output Obsidian notes
#
# Usage:
#   ./run-research.sh RES-102                    Single task
#   ./run-research.sh RES-102 RES-103 RES-104    Multiple tasks (sequential)
#   ./run-research.sh RES-102 RES-103 --parallel  Multiple tasks (parallel, max 3)
#   ./run-research.sh RES-102 --max-turns 60      Custom max turns

set -euo pipefail

# Load environment
if [ -f "$HOME/.bashrc" ]; then
  source "$HOME/.bashrc" 2>/dev/null || true
fi

# Constants
LINEAR_API="https://api.linear.app/graphql"
NOTE_DIR="$HOME/Desktop/Note"
DRAFTS_DIR="$NOTE_DIR/Drafts"
TEMPLATE_DIR="$NOTE_DIR/Templates"
STATE_IN_PROGRESS="1eec99d9-f87d-4db5-ad26-04911f9aab50"
STATE_IN_REVIEW="c946ae27-9e8a-48e9-9f02-c8d08cdbf84c"
LOG_DIR="$HOME/.claude/logs"
MAX_TURNS=40
MAX_CONCURRENT=3

mkdir -p "$LOG_DIR" "$DRAFTS_DIR"

# Verify environment
if [ -z "${LINEAR_API_KEY:-}" ]; then
  echo "ERROR: LINEAR_API_KEY is not set." >&2
  exit 1
fi

# Parse arguments
ISSUES=()
PARALLEL=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --parallel)
      PARALLEL=true
      shift
      ;;
    --max-turns)
      MAX_TURNS="$2"
      shift 2
      ;;
    RES-*|res-*)
      ISSUES+=("${1^^}")
      shift
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Usage: run-research.sh <RES-NNN...> [--parallel] [--max-turns N]" >&2
      exit 1
      ;;
  esac
done

if [ ${#ISSUES[@]} -eq 0 ]; then
  echo "Usage: run-research.sh <RES-NNN...> [--parallel] [--max-turns N]" >&2
  exit 1
fi

# --- Linear API helpers ---

linear_query() {
  curl -s -X POST "$LINEAR_API" \
    -H "Content-Type: application/json" \
    -H "Authorization: $LINEAR_API_KEY" \
    -d "$1"
}

get_issue() {
  local identifier="$1"
  linear_query "{\"query\": \"{ issue(id: \\\"$identifier\\\") { id identifier title description state { name } } }\"}" \
    | python3 -c "
import sys, json
data = json.load(sys.stdin)
n = data.get('data', {}).get('issue')
if not n:
    sys.exit(1)
print(n['id'])
print(n['identifier'])
print(n['title'])
print(n['state']['name'])
print(n.get('description') or 'No description provided.')
"
}

set_state() {
  local issue_id="$1"
  local state_id="$2"
  linear_query "{\"query\": \"mutation { issueUpdate(id: \\\"$issue_id\\\", input: { stateId: \\\"$state_id\\\" }) { success } }\"}" > /dev/null
}

notify() {
  if [ -n "${DISCORD_WEBHOOK_URL:-}" ]; then
    curl -s -X POST "$DISCORD_WEBHOOK_URL" \
      -H "Content-Type: application/json" \
      -d "{\"content\": \"$1\"}" > /dev/null
  else
    echo "  [notify] $1"
  fi
}

# --- Run a single research task ---

run_research() {
  local IDENTIFIER="$1"
  local POSITION="$2"
  local TOTAL="$3"
  local LOG_FILE="$LOG_DIR/research-${IDENTIFIER}-$(date +%Y%m%d-%H%M%S).log"

  echo "=== [$POSITION/$TOTAL] $IDENTIFIER ==="

  # Fetch issue details
  local ISSUE_DATA
  ISSUE_DATA=$(get_issue "$IDENTIFIER") || {
    echo "  ERROR: $IDENTIFIER not found in Linear." >&2
    notify "Research $IDENTIFIER: not found in Linear"
    return 1
  }

  local ISSUE_ID ISSUE_TITLE ISSUE_STATE ISSUE_DESC
  ISSUE_ID=$(echo "$ISSUE_DATA" | sed -n '1p')
  ISSUE_TITLE=$(echo "$ISSUE_DATA" | sed -n '3p')
  ISSUE_STATE=$(echo "$ISSUE_DATA" | sed -n '4p')
  ISSUE_DESC=$(echo "$ISSUE_DATA" | sed -n '5,$p')

  echo "  Title: $ISSUE_TITLE"
  echo "  State: $ISSUE_STATE"

  # Set In Progress
  set_state "$ISSUE_ID" "$STATE_IN_PROGRESS"
  echo "  -> In Progress"
  notify "Research started: $IDENTIFIER - $ISSUE_TITLE"

  # Build prompt
  local PROMPT
  read -r -d '' PROMPT <<PROMPT_EOF || true
You are a research assistant. Investigate the following topic and create an Obsidian note.

## Task
- Linear Issue: $IDENTIFIER
- Title: $ISSUE_TITLE
- Description: $ISSUE_DESC

## Output
Write the note to: $DRAFTS_DIR/
- Use a descriptive filename (e.g., SoftRoboticsOverview.md, Author2024_PaperTitle.md).
- Use the template at $TEMPLATE_DIR/Research Draft.md as the base format.
- Fill in the frontmatter fields (title, linear, authors, year, venue where applicable).
- Use [[wikilinks]] to link to related concepts where relevant.
- Do NOT create checkboxes or TODO items in the note.

## Research Rules (CRITICAL)
1. Every factual claim MUST have a source with: paper title, authors, year, and URL.
2. If you cannot verify a claim via web search, mark it with [Unverified].
3. Do NOT write claims based solely on your training data without verification via web search.
4. Keep "Findings" (facts from sources) and "Synthesis" (your interpretation) strictly separated.
5. Quote important numbers, metrics, and conclusions in the original English.
6. If information is not found, leave the field empty rather than guessing.
7. In the "Verification Notes" section, list:
   - Which sources you accessed and verified
   - Any claims that remain unverified
   - Suggested follow-up searches for the reviewer

## Existing Notes
Check $NOTE_DIR/Literature/ and $NOTE_DIR/Concepts/ for existing notes that may be relevant. Link to them with [[wikilinks]] but do not modify them.

Print a brief summary of what you created when done.
PROMPT_EOF

  # Run Claude
  claude -p "$PROMPT" \
    --allowedTools "Edit,Write,Read,Glob,Grep,Bash,Agent,WebSearch,WebFetch" \
    --max-turns "$MAX_TURNS" \
    > "$LOG_FILE" 2>&1

  local EXIT_CODE=$?

  if [ $EXIT_CODE -ne 0 ]; then
    echo "  ERROR: exit code $EXIT_CODE. Log: $LOG_FILE"
    notify "Research $IDENTIFIER ($ISSUE_TITLE) failed (exit $EXIT_CODE)"
    return $EXIT_CODE
  fi

  # Set In Review
  set_state "$ISSUE_ID" "$STATE_IN_REVIEW"
  echo "  -> In Review"
  echo "  Done. Log: $LOG_FILE"
  notify "Research complete: $IDENTIFIER ($ISSUE_TITLE) — ready for review"
}

# --- Execute ---

TOTAL=${#ISSUES[@]}
echo "Tasks: ${ISSUES[*]} ($TOTAL total, max-turns: $MAX_TURNS)"

if [ "$TOTAL" -gt 1 ]; then
  notify "Research queue started: ${ISSUES[*]} ($TOTAL tasks)"
fi

if [ "$PARALLEL" = true ] && [ "$TOTAL" -gt 1 ]; then
  echo "Mode: parallel (max $MAX_CONCURRENT)"
  PIDS=()
  FAILED=0

  for i in "${!ISSUES[@]}"; do
    # Wait if at concurrency limit
    while [ ${#PIDS[@]} -ge "$MAX_CONCURRENT" ]; do
      NEW_PIDS=()
      for pid in "${PIDS[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
          NEW_PIDS+=("$pid")
        else
          wait "$pid" || FAILED=$((FAILED + 1))
        fi
      done
      PIDS=("${NEW_PIDS[@]}")
      [ ${#PIDS[@]} -ge "$MAX_CONCURRENT" ] && sleep 5
    done

    run_research "${ISSUES[$i]}" "$((i + 1))" "$TOTAL" &
    PIDS+=($!)
  done

  for pid in "${PIDS[@]}"; do
    wait "$pid" || FAILED=$((FAILED + 1))
  done

  if [ "$FAILED" -eq 0 ]; then
    echo "=== All $TOTAL tasks completed ==="
    notify "All $TOTAL research tasks completed: ${ISSUES[*]}"
  else
    echo "=== $FAILED/$TOTAL tasks failed ==="
    notify "$FAILED/$TOTAL research tasks failed: ${ISSUES[*]}"
    exit 1
  fi
else
  echo "Mode: sequential"
  for i in "${!ISSUES[@]}"; do
    run_research "${ISSUES[$i]}" "$((i + 1))" "$TOTAL" || {
      echo "Task ${ISSUES[$i]} failed. Stopping." >&2
      exit 1
    }
  done
  echo "=== All $TOTAL tasks completed ==="
  [ "$TOTAL" -gt 1 ] && notify "All $TOTAL research tasks completed: ${ISSUES[*]}"
fi
