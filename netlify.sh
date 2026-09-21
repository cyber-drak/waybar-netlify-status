#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/netlify.env"

fail() {
  jq -cn --arg text $'\uf057' \
    '{text: $text, class: "error", tooltip: "Netlify: API unavailable"}'
  exit 0
}

deploy=$(curl -fsS \
  -H "Authorization: Bearer $NETLIFY_AUTH_TOKEN" \
  "https://api.netlify.com/api/v1/sites/$NETLIFY_SITE_ID/deploys?per_page=1") \
  || fail

deploy=$(jq '.[0]' <<<"$deploy")

state=$(jq -r '.state // "unknown"' <<<"$deploy")
title=$(jq -r '.title // "—"' <<<"$deploy")
branch=$(jq -r '.branch // "?"' <<<"$deploy")
commit=$(jq -r '.commit_ref // ""' <<<"$deploy" | cut -c1-7)
author=$(jq -r '.committer // "?"' <<<"$deploy")
created=$(jq -r '.created_at // "?"' <<<"$deploy" | cut -d. -f1)
deploy_time=$(jq -r '.deploy_time // 0' <<<"$deploy")
error=$(jq -r '.error_message // empty' <<<"$deploy")

case "$state" in
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
    label="FAILED"
    ;;
  *)
    icon=$'\uf05a'
    label="${state^^}"
    ;;
esac

tooltip="$icon $label
$title

Branch: $branch
Commit: $commit
Author: $author
Created: $created
Deploy time: ${deploy_time}s"

[[ -n "$error" ]] && tooltip+=$'\n\n'"Error: $error"

jq -cn \
  --arg text "$icon $label" \
  --arg class "$class" \
  --arg tooltip "$tooltip" \
  '{text: $text, class: $class, tooltip: $tooltip}'
