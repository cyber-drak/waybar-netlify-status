#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/.env"

fail() {
  jq -cn --arg text $'\uf057' \
    '{text: $text, tooltip: "Netlify: API unavailable"}'
  exit 0
}

tooltip=""
overall_state="ready"

for site in "${NETLIFY_SITES[@]}"; do
  project="${site%%:*}"
  site_id="${site#*:}"

  deploy=$(curl -fsS \
    -H "Authorization: Bearer $NETLIFY_AUTH_TOKEN" \
    "https://api.netlify.com/api/v1/sites/$site_id/deploys?per_page=1") ||
    fail

  deploy=$(jq '.[0]' <<<"$deploy")

  state=$(jq -r '.state // "unknown"' <<<"$deploy")
  title=$(jq -r '.title // .commit_message // "N/A"' <<<"$deploy")
  branch=$(jq -r '.branch // "?"' <<<"$deploy")
  commit=$(jq -r '.commit_ref // ""' <<<"$deploy" | cut -c1-7)
  author=$(jq -r '.committer // "?"' <<<"$deploy")
  created=$(jq -r '.created_at // "?"' <<<"$deploy" | cut -d. -f1)
  deploy_time=$(jq -r '.deploy_time // 0' <<<"$deploy")
  error=$(jq -r '.error_message // empty' <<<"$deploy")

  case "$state" in
  ready) icon=$'\uf058' ;;
  enqueued) icon=$'\uf017' ;;
  building) icon=$'\uf110' ;;
  error) icon=$'\uf057' ;;
  *) icon=$'\uf05a' ;;
  esac

  if [[ "$state" == "ready" ]]; then
    label="OK"
  else
    label="${state^^}"
  fi

  [[ -n "$tooltip" ]] && tooltip+=$'\n\n'

  tooltip="$tooltip$icon $project $label
$title

Branch: $branch
Commit: $commit
Author: $author
Created: $created
Deploy time: ${deploy_time}s"

  [[ -n "$error" ]] && tooltip+=$'\n\n'"Error: $error"

  if [[ "$state" == "error" ]]; then
    overall_state="error"
  elif [[ "$state" == "building" || "$state" == "enqueued" ]] && [[ "$overall_state" != "error" ]]; then
    overall_state="building"
  fi
done

case "$overall_state" in
ready)
  icon=$'\uf058'
  label="OK"
  ;;
building)
  icon=$'\uf110'
  label="BUILDING"
  ;;
error)
  icon=$'\uf057'
  label="ERROR"
  ;;
esac

jq -cn \
  --arg text "$icon $label" \
  --arg tooltip "$tooltip" \
  '{text: $text, tooltip: $tooltip}'
