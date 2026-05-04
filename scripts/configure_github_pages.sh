#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=load_healthybrain_env.sh
. "$SCRIPT_DIR/load_healthybrain_env.sh"

API_BASE="https://api.github.com"
API_VERSION="2026-03-10"
OWNER="${GITHUB_OWNER:-wolfgang-ganglberger}"
REPO="${GITHUB_REPO:-healthybrain.ai}"
CUSTOM_DOMAIN="${GITHUB_PAGES_CUSTOM_DOMAIN:-healthybrain.ai}"
SOURCE_BRANCH="${GITHUB_PAGES_SOURCE_BRANCH:-main}"
SOURCE_PATH="${GITHUB_PAGES_SOURCE_PATH:-/}"
ENFORCE_HTTPS="${GITHUB_PAGES_ENFORCE_HTTPS:-false}"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_env() {
  if [ -z "${!1:-}" ]; then
    echo "Missing required environment variable: $1" >&2
    exit 1
  fi
}

github_request() {
  local method="$1"
  local path="$2"
  local payload="${3:-}"
  local tmp_body
  local status

  tmp_body="$(mktemp)"

  if [ -n "$payload" ]; then
    status="$(curl -sS -o "$tmp_body" -w "%{http_code}" \
      -X "$method" \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer $GITHUB_TOKEN" \
      -H "X-GitHub-Api-Version: $API_VERSION" \
      -H "Content-Type: application/json" \
      "$API_BASE$path" \
      -d "$payload")"
  else
    status="$(curl -sS -o "$tmp_body" -w "%{http_code}" \
      -X "$method" \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer $GITHUB_TOKEN" \
      -H "X-GitHub-Api-Version: $API_VERSION" \
      "$API_BASE$path")"
  fi

  printf "%s\n" "$status"
  cat "$tmp_body"
  rm -f "$tmp_body"
}

main() {
  require_command curl
  require_command jq
  require_env GITHUB_TOKEN

  local pages_path="/repos/$OWNER/$REPO/pages"
  local create_payload
  local update_payload
  local response
  local status
  local body

  create_payload="$(jq -n \
    --arg branch "$SOURCE_BRANCH" \
    --arg path "$SOURCE_PATH" \
    '{source: {branch: $branch, path: $path}}')"

  update_payload="$(jq -n \
    --arg cname "$CUSTOM_DOMAIN" \
    --arg branch "$SOURCE_BRANCH" \
    --arg path "$SOURCE_PATH" \
    --argjson https_enforced "$ENFORCE_HTTPS" \
    '{
      cname: $cname,
      build_type: "legacy",
      source: {branch: $branch, path: $path},
      https_enforced: $https_enforced
    }')"

  echo "Checking GitHub Pages site for $OWNER/$REPO"
  response="$(github_request GET "$pages_path")"
  status="$(head -n 1 <<<"$response")"
  body="$(tail -n +2 <<<"$response")"

  if [ "$status" = "404" ]; then
    echo "Creating GitHub Pages site from $SOURCE_BRANCH:$SOURCE_PATH"
    response="$(github_request POST "$pages_path" "$create_payload")"
    status="$(head -n 1 <<<"$response")"
    body="$(tail -n +2 <<<"$response")"
    if [ "$status" != "201" ]; then
      echo "Failed to create GitHub Pages site." >&2
      echo "$body" >&2
      exit 1
    fi
  elif [ "$status" != "200" ]; then
    echo "Failed to inspect GitHub Pages site." >&2
    echo "$body" >&2
    exit 1
  fi

  echo "Setting custom domain to $CUSTOM_DOMAIN"
  response="$(github_request PUT "$pages_path" "$update_payload")"
  status="$(head -n 1 <<<"$response")"
  body="$(tail -n +2 <<<"$response")"
  if [ "$status" != "204" ]; then
    echo "Failed to update GitHub Pages settings." >&2
    echo "$body" >&2
    exit 1
  fi

  echo "Done. If DNS is not propagated yet, keep GITHUB_PAGES_ENFORCE_HTTPS=false and re-run later with true."
}

main "$@"
