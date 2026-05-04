#!/usr/bin/env bash

if [ -n "${HEALTHYBRAIN_ENV_LOADED:-}" ]; then
  return 0 2>/dev/null || exit 0
fi

HEALTHYBRAIN_ENV_LOADED=1
HEALTHYBRAIN_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HEALTHYBRAIN_REPO_ROOT="$(cd "$HEALTHYBRAIN_SCRIPT_DIR/.." && pwd)"
HEALTHYBRAIN_ENV_FILE="${HEALTHYBRAIN_ENV_FILE:-$HEALTHYBRAIN_REPO_ROOT/.env.local}"
HEALTHYBRAIN_FALLBACK_ENV_FILE="$HEALTHYBRAIN_REPO_ROOT/../wolfgang-ganglberger.github.io/.env.local"

if [ -f "$HEALTHYBRAIN_ENV_FILE" ]; then
  set -a
  # shellcheck disable=SC1090
  . "$HEALTHYBRAIN_ENV_FILE"
  set +a
elif [ -f "$HEALTHYBRAIN_FALLBACK_ENV_FILE" ]; then
  set -a
  # shellcheck disable=SC1090
  . "$HEALTHYBRAIN_FALLBACK_ENV_FILE"
  set +a
fi
