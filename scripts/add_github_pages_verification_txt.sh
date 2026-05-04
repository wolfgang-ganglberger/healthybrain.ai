#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=load_healthybrain_env.sh
. "$SCRIPT_DIR/load_healthybrain_env.sh"

API_BASE="https://api.porkbun.com/api/json/v3"
DOMAIN="healthybrain.ai"
DEFAULT_RECORD_NAME="_github-pages-challenge-wolfgang-ganglberger"
TTL=600

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

auth_json() {
  jq -n \
    --arg apikey "$PORKBUN_API_KEY" \
    --arg secretapikey "$PORKBUN_SECRET_API_KEY" \
    '{apikey: $apikey, secretapikey: $secretapikey}'
}

post_json() {
  local url="$1"
  local payload="$2"
  local response

  response="$(curl -fsS -X POST "$url" \
    -H "Content-Type: application/json" \
    -d "$payload")"

  local status
  status="$(jq -r '.status // "ERROR"' <<<"$response")"
  if [ "$status" != "SUCCESS" ]; then
    echo "Porkbun API request failed: $url" >&2
    echo "$response" >&2
    exit 1
  fi

  echo "$response"
}

delete_conflicting_record_ids() {
  local fqdn="$1"
  local records

  records="$(post_json "$API_BASE/dns/retrieve/$DOMAIN" "$(auth_json)")"
  jq -r \
    --arg fqdn "$fqdn" \
    '.records[]? | select(.name == $fqdn and (.type == "TXT" or .type == "CNAME")) | .id' \
    <<<"$records" | while read -r id; do
      [ -z "$id" ] && continue
      echo "Deleting conflicting DNS record $id on $DOMAIN"
      post_json "$API_BASE/dns/delete/$DOMAIN/$id" "$(auth_json)" >/dev/null
    done
}

create_txt_record() {
  local name="$1"
  local value="$2"
  local payload

  payload="$(auth_json | jq \
    --arg name "$name" \
    --arg value "$value" \
    --argjson ttl "$TTL" \
    '. + {type: "TXT", name: $name, content: $value, ttl: $ttl}')"

  echo "Creating TXT $name.$DOMAIN"
  post_json "$API_BASE/dns/create/$DOMAIN" "$payload" >/dev/null
}

main() {
  require_command curl
  require_command jq
  require_env PORKBUN_API_KEY
  require_env PORKBUN_SECRET_API_KEY

  local record_name="${GITHUB_PAGES_VERIFY_NAME:-$DEFAULT_RECORD_NAME}"
  local record_value="${GITHUB_PAGES_VERIFY_VALUE:-${1:-}}"

  if [ -z "$record_value" ]; then
    echo "Usage: GITHUB_PAGES_VERIFY_VALUE='<value from GitHub>' $0" >&2
    echo "Or pass the value as the first argument." >&2
    exit 1
  fi

  delete_conflicting_record_ids "$record_name.$DOMAIN"
  create_txt_record "$record_name" "$record_value"

  echo "Check propagation with:"
  echo "dig $record_name.$DOMAIN +nostats +nocomments +nocmd TXT"
}

main "$@"
