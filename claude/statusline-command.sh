#!/bin/bash
# Claude Code Status Line - 3行構成
# Line 1: モデル名 │ コンテキスト使用率 │ +/-行数 │ gitブランチ
# Line 2: 5時間レートリミット プログレスバー
# Line 3: 7日間レートリミット プログレスバー

CACHE_FILE="/tmp/claude-usage-cache.json"
CACHE_TTL=360
CRED_FILE="$HOME/.claude/.credentials.json"

input=$(cat)

# === Parse stdin JSON ===
model=$(echo "$input" | jq -r '.model.display_name // "unknown"')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // "0"')
lines_added=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
lines_removed=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')

# Git branch
git_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "-")

# Round context percentage
pct_int=$(awk "BEGIN {printf \"%.0f\", ${used_pct:-0}}" 2>/dev/null || echo "0")

# === Colors (using $'...' syntax for proper escape handling) ===
GREEN=$'\033[38;2;151;201;195m'
YELLOW=$'\033[38;2;229;192;123m'
RED=$'\033[38;2;224;108;117m'
GRAY=$'\033[38;2;74;88;92m'
RESET=$'\033[0m'

color_for_pct() {
  local p=$1
  if [ "$p" -ge 80 ]; then
    printf '%s' "$RED"
  elif [ "$p" -ge 50 ]; then
    printf '%s' "$YELLOW"
  else
    printf '%s' "$GREEN"
  fi
}

# === Progress bar (10 segments, ▰▱) ===
progress_bar() {
  local pct=$1
  local filled=$((pct / 10))
  [ "$filled" -gt 10 ] && filled=10
  local empty=$((10 - filled))
  local bar=""
  for ((i = 0; i < filled; i++)); do bar+="▰"; done
  for ((i = 0; i < empty; i++)); do bar+="▱"; done
  printf '%s' "$bar"
}

# === Fetch usage from API (with cache) ===
fetch_usage() {
  local now
  now=$(date +%s)

  # Check cache
  if [ -f "$CACHE_FILE" ]; then
    local cache_ts
    cache_ts=$(jq -r '.cached_at // 0' "$CACHE_FILE" 2>/dev/null)
    local age=$((now - cache_ts))
    if [ "$age" -lt "$CACHE_TTL" ]; then
      return 0
    fi
  fi

  # Get OAuth token
  if [ ! -f "$CRED_FILE" ]; then
    return 1
  fi
  local token
  token=$(jq -r '.claudeAiOauth.accessToken // empty' "$CRED_FILE" 2>/dev/null)
  if [ -z "$token" ]; then
    return 1
  fi

  # Call API
  local resp
  resp=$(curl -s --max-time 5 \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/json" \
    -H "User-Agent: claude-code/2.1.76" \
    -H "anthropic-beta: oauth-2025-04-20" \
    "https://api.anthropic.com/api/oauth/usage" 2>/dev/null)

  # Validate response and cache
  if echo "$resp" | jq -e '.five_hour' >/dev/null 2>&1; then
    echo "$resp" | jq --argjson ts "$now" '. + {cached_at: $ts}' > "$CACHE_FILE"
  fi
}

fetch_usage

# Read cached values
five_hour_util=0
five_hour_resets=""
seven_day_util=0
seven_day_resets=""

if [ -f "$CACHE_FILE" ]; then
  five_hour_util=$(jq -r '.five_hour.utilization // 0' "$CACHE_FILE" 2>/dev/null)
  five_hour_resets=$(jq -r '.five_hour.resets_at // ""' "$CACHE_FILE" 2>/dev/null)
  seven_day_util=$(jq -r '.seven_day.utilization // 0' "$CACHE_FILE" 2>/dev/null)
  seven_day_resets=$(jq -r '.seven_day.resets_at // ""' "$CACHE_FILE" 2>/dev/null)
fi

# Round utilization to integer
five_pct=$(awk "BEGIN {printf \"%.0f\", ${five_hour_util:-0}}" 2>/dev/null || echo "0")
seven_pct=$(awk "BEGIN {printf \"%.0f\", ${seven_day_util:-0}}" 2>/dev/null || echo "0")

# === Format reset times in Asia/Tokyo (force English locale) ===
format_reset_5h() {
  local iso="$1"
  if [ -z "$iso" ] || [ "$iso" = "null" ]; then
    echo "--"
    return
  fi
  if [ "$(uname)" = "Darwin" ]; then
    LC_ALL=en_US.UTF-8 TZ="Asia/Tokyo" date -jf "%Y-%m-%dT%H:%M:%S" "$(echo "$iso" | sed 's/Z$//; s/\.[0-9]*//' | sed 's/+.*//')" "+%-I%p" 2>/dev/null | tr 'AP' 'ap' | tr 'M' 'm' || echo "--"
  else
    LC_ALL=en_US.UTF-8 TZ="Asia/Tokyo" date -d "$iso" "+%-I%p" 2>/dev/null | tr 'AP' 'ap' | tr 'M' 'm' || echo "--"
  fi
}

format_reset_7d() {
  local iso="$1"
  if [ -z "$iso" ] || [ "$iso" = "null" ]; then
    echo "--"
    return
  fi
  if [ "$(uname)" = "Darwin" ]; then
    LC_ALL=en_US.UTF-8 TZ="Asia/Tokyo" date -jf "%Y-%m-%dT%H:%M:%S" "$(echo "$iso" | sed 's/Z$//; s/\.[0-9]*//' | sed 's/+.*//')" "+%b %-d at %-I%p" 2>/dev/null | sed 's/AM/am/g;s/PM/pm/g' || echo "--"
  else
    LC_ALL=en_US.UTF-8 TZ="Asia/Tokyo" date -d "$iso" "+%b %-d at %-I%p" 2>/dev/null | sed 's/AM/am/g;s/PM/pm/g' || echo "--"
  fi
}

five_reset_str=$(format_reset_5h "$five_hour_resets")
seven_reset_str=$(format_reset_7d "$seven_day_resets")

# === Build components ===
ctx_color=$(color_for_pct "$pct_int")
five_color=$(color_for_pct "$five_pct")
seven_color=$(color_for_pct "$seven_pct")

five_bar=$(progress_bar "$five_pct")
seven_bar=$(progress_bar "$seven_pct")

sep="${GRAY}│${RESET}"

# === Output 3 lines ===
# Line 1: 🤖 Model │ 📊 Context% │ ✏️ +/-lines │ 🔀 branch
printf '🤖 %s %s 📊 %s%d%%%s %s ✏️ +%s/-%s %s 🔀 %s\n' \
  "$model" "$sep" "$ctx_color" "$pct_int" "$RESET" "$sep" "$lines_added" "$lines_removed" "$sep" "$git_branch"

# Line 2: ⏱ 5h  ▰▱▱▱▱▱▱▱▱▱  13%  Resets 4pm (Asia/Tokyo)
printf '⏱ 5h  %s%s  %d%%%s  Resets %s (Asia/Tokyo)\n' \
  "$five_color" "$five_bar" "$five_pct" "$RESET" "$five_reset_str"

# Line 3: 📅 7d  ▰▰▰▰▰▱▱▱▱▱  55%  Resets Mar 6 at 1pm (Asia/Tokyo)
printf '📅 7d  %s%s  %d%%%s  Resets %s (Asia/Tokyo)\n' \
  "$seven_color" "$seven_bar" "$seven_pct" "$RESET" "$seven_reset_str"
