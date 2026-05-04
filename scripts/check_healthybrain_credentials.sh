#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=load_healthybrain_env.sh
. "$SCRIPT_DIR/load_healthybrain_env.sh"

API_VERSION="2026-03-10"
GITHUB_OWNER="${GITHUB_OWNER:-wolfgang-ganglberger}"
GITHUB_REPO="${GITHUB_REPO:-healthybrain.ai}"
PORKBUN_API_BASE="https://api.porkbun.com/api/json/v3"
DOMAIN="healthybrain.ai"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_env() {
  if [ -z "${!1:-}" ]; then
    echo "Missing required environment variable: $1" >&2
    echo "Create .env.local from .env.local.example, or configure ../wolfgang-ganglberger.github.io/.env.local." >&2
    exit 1
  fi
}

auth_json() {
  jq -n \
    --arg apikey "$PORKBUN_API_KEY" \
    --arg secretapikey "$PORKBUN_SECRET_API_KEY" \
    '{apikey: $apikey, secretapikey: $secretapikey}'
}

github_get() {
  local path="$1"
  local tmp_body
  local status

  tmp_body="$(mktemp)"
  status="$(curl -sS -o "$tmp_body" -w "%{http_code}" \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "X-GitHub-Api-Version: $API_VERSION" \
    "https://api.github.com$path")"

  printf "%s\n" "$status"
  cat "$tmp_body"
  rm -f "$tmp_body"
}

porkbun_post() {
  local path="$1"
  local payload="$2"
  local tmp_body
  local status

  tmp_body="$(mktemp)"
  status="$(curl -sS -o "$tmp_body" -w "%{http_code}" \
    -X POST "$PORKBUN_API_BASE$path" \
    -H "Content-Type: application/json" \
    -d "$payload")"

  printf "%s\n" "$status"
  cat "$tmp_body"
  rm -f "$tmp_body"
}

main() {
  local response
  local status
  local body

  require_command curl
  require_command jq
  require_env GITHUB_TOKEN
  require_env PORKBUN_API_KEY
  require_env PORKBUN_SECRET_API_KEY

  echo "Checking GitHub token..."
  response="$(github_get /user)"
  status="$(head -n 1 <<<"$response")"
  body="$(tail -n +2 <<<"$response")"
  if [ "$status" != "200" ]; then
    echo "GitHub token check failed." >&2
    echo "$body" >&2
    exit 1
  fi
  echo "GitHub token valid for: $(jq -r '.login // empty' <<<"$body")"

  response="$(github_get "/repos/$GITHUB_OWNER/$GITHUB_REPO")"
  status="$(head -n 1 <<<"$response")"
  body="$(tail -n +2 <<<"$response")"
  if [ "$status" = "200" ]; then
    echo "GitHub repo access confirmed: $GITHUB_OWNER/$GITHUB_REPO"
  elif [ "$status" = "404" ]; then
    echo "GitHub repo $GITHUB_OWNER/$GITHUB_REPO is not accessible yet." >&2
    echo "Create it and push this repository before running GitHub Pages automation." >&2
    exit 1
  else
    echo "GitHub repo access check returned unexpected status $status." >&2
    echo "$body" >&2
    exit 1
  fi

  echo "Checking Porkbun credentials..."
  response="$(porkbun_post /ping "$(auth_json)")"
  status="$(head -n 1 <<<"$response")"
  body="$(tail -n +2 <<<"$response")"
  if [ "$status" != "200" ] || [ "$(jq -r '.credentialsValid // false' <<<"$body")" != "true" ]; then
    echo "Porkbun credential check failed." >&2
    echo "$body" >&2
    exit 1
  fi
  echo "Porkbun credentials valid."

  response="$(porkbun_post "/dns/retrieve/$DOMAIN" "$(auth_json)")"
  status="$(head -n 1 <<<"$response")"
  body="$(tail -n +2 <<<"$response")"
  if [ "$status" != "200" ] || [ "$(jq -r '.status // "ERROR"' <<<"$body")" != "SUCCESS" ]; then
    echo "Porkbun domain API access failed for $DOMAIN." >&2
    echo "Make sure API access is enabled for $DOMAIN in Porkbun." >&2
    echo "$body" >&2
    exit 1
  fi
  echo "Porkbun domain API access confirmed: $DOMAIN"
}

main "$@"
