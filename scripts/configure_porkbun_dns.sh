#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=load_healthybrain_env.sh
. "$SCRIPT_DIR/load_healthybrain_env.sh"

API_BASE="https://api.porkbun.com/api/json/v3"
DOMAIN="healthybrain.ai"
GITHUB_PAGES_HOST="wolfgang-ganglberger.github.io"
TTL=600

GITHUB_A_RECORDS=(
  "185.199.108.153"
  "185.199.109.153"
  "185.199.110.153"
  "185.199.111.153"
)

GITHUB_AAAA_RECORDS=(
  "2606:50c0:8000::153"
  "2606:50c0:8001::153"
  "2606:50c0:8002::153"
  "2606:50c0:8003::153"
)

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

delete_record_id() {
  local id="$1"
  post_json "$API_BASE/dns/delete/$DOMAIN/$id" "$(auth_json)" >/dev/null
}

delete_conflicting_dns_records() {
  local records

  records="$(post_json "$API_BASE/dns/retrieve/$DOMAIN" "$(auth_json)")"
  jq -r \
    '.records[]? | select((.name == "'"$DOMAIN"'" and (.type == "A" or .type == "AAAA" or .type == "ALIAS" or .type == "CNAME")) or (.name == "www.'"$DOMAIN"'" and (.type == "A" or .type == "AAAA" or .type == "ALIAS" or .type == "CNAME"))) | .id' \
    <<<"$records" | while read -r id; do
      [ -z "$id" ] && continue
      echo "Deleting DNS record $id on $DOMAIN"
      delete_record_id "$id"
    done
}

create_dns_record() {
  local type="$1"
  local name="$2"
  local content="$3"
  local payload

  payload="$(auth_json | jq \
    --arg type "$type" \
    --arg name "$name" \
    --arg content "$content" \
    --argjson ttl "$TTL" \
    '. + {type: $type, name: $name, content: $content, ttl: $ttl}')"

  echo "Creating $type ${name:-@} -> $content on $DOMAIN"
  post_json "$API_BASE/dns/create/$DOMAIN" "$payload" >/dev/null
}

main() {
  require_command curl
  require_command jq
  require_env PORKBUN_API_KEY
  require_env PORKBUN_SECRET_API_KEY

  echo "Configuring $DOMAIN for GitHub Pages"
  delete_conflicting_dns_records

  for ip in "${GITHUB_A_RECORDS[@]}"; do
    create_dns_record "A" "" "$ip"
  done

  for ip in "${GITHUB_AAAA_RECORDS[@]}"; do
    create_dns_record "AAAA" "" "$ip"
  done

  create_dns_record "CNAME" "www" "$GITHUB_PAGES_HOST"

  echo "Done. DNS propagation can take up to 24 hours."
}

main "$@"
